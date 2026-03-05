import urllib.request
import urllib.parse
import json
import threading

from languages import get_english_name


def _google_request(text, target_lang, timeout=10):
    """Raw Google Translate call. Returns (translated, source_lang) or (None, None)."""
    try:
        encoded = urllib.parse.quote(text)
        url = (
            f"https://translate.googleapis.com/translate_a/single"
            f"?client=gtx&sl=auto&tl={target_lang}&dt=t&q={encoded}"
        )
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0')
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read())
            segments = data[0] if data else []
            translated = ''.join(seg[0] for seg in segments if seg and seg[0])
            source_lang = data[2] if len(data) > 2 else None
            return (translated or None, source_lang)
    except Exception as e:
        print(f"[Google] {e}")
        return (None, None)


def _translate_google(text, target_lang, callback):
    def _run():
        translated, source_lang = _google_request(text, target_lang)
        callback(translated, source_lang)
    threading.Thread(target=_run, daemon=True).start()


def _translate_gemini(text, target_lang, api_key, tone, gender, callback):
    def _run():
        # Detect source language quickly via Google
        _, source_lang = _google_request(text[:200], 'en', timeout=5)

        # Build Gemini prompt
        lang_name = get_english_name(target_lang)
        tone_desc = "casual and natural" if tone == "casual" else "polite and formal"

        lang_specific = ""
        if target_lang == "th":
            particle = "ครับ" if gender == "masculin" else "ค่ะ"
            lang_specific = (
                "Use นะ, เลย for casual endings. " if tone == "casual"
                else f"End sentences with {particle}. "
            )
        elif target_lang == "ja":
            lang_specific = (
                "Use 普通体 (plain form). " if tone == "casual"
                else "Use 丁寧語 (polite -ます/-です form). "
            )
        elif target_lang == "ko":
            lang_specific = (
                "Use 반말 (informal speech). " if tone == "casual"
                else "Use 존댓말 (formal speech). "
            )
        elif target_lang == "de":
            lang_specific = (
                "Use 'du' form. " if tone == "casual"
                else "Use 'Sie' form. "
            )

        prompt = (
            f"You are a universal translation assistant. "
            f"Auto-detect the source language. "
            f"Correct grammar errors, translate to {lang_name}, tone: {tone_desc}. "
            f"{lang_specific}"
            f"If the text is already in the target language, only correct it. "
            f"Reply ONLY with the final translated text, no quotes, no explanation.\n\n"
            f"Text: {text}"
        )

        try:
            url = (
                f"https://generativelanguage.googleapis.com/v1beta/models/"
                f"gemini-2.0-flash:generateContent?key={api_key}"
            )
            body = {
                "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                "generationConfig": {"temperature": 0.3, "maxOutputTokens": 1024},
            }
            body_bytes = json.dumps(body).encode('utf-8')
            req = urllib.request.Request(url, data=body_bytes, method='POST')
            req.add_header('Content-Type', 'application/json')
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
                translated = (
                    data['candidates'][0]['content']['parts'][0]['text'].strip()
                )
                callback(translated, source_lang)
        except Exception as e:
            print(f"[Gemini] {e} — falling back to Google")
            translated, sl = _google_request(text, target_lang)
            callback(translated, sl or source_lang)

    threading.Thread(target=_run, daemon=True).start()


def translate(text, settings, callback):
    """Main entry point. Calls callback(translated_text, source_lang)."""
    target_lang = settings.get('target_language')
    api_key = settings.get('gemini_api_key')
    tone = settings.get('tone')
    gender = settings.get('gender')

    if api_key:
        _translate_gemini(text, target_lang, api_key, tone, gender, callback)
    else:
        _translate_google(text, target_lang, callback)
