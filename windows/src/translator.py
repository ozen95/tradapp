import urllib.request
import urllib.parse
import json
import threading

from languages import get_english_name

NO_KEY_MSG = "⚠️ Clé API Gemini manquante — ouvre les Préférences pour l'ajouter."


def _call_gemini(text, target_lang, api_key, tone, gender, callback):
    def _run():
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
            req = urllib.request.Request(
                url, data=json.dumps(body).encode('utf-8'), method='POST'
            )
            req.add_header('Content-Type', 'application/json')
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
                translated = (
                    data['candidates'][0]['content']['parts'][0]['text'].strip()
                )
                callback(translated, None)
        except Exception as e:
            print(f"[Gemini] {e}")
            callback(None, None)

    threading.Thread(target=_run, daemon=True).start()


def translate(text, settings, callback):
    """Main entry point. Calls callback(translated_text, source_lang)."""
    api_key = settings.get('gemini_api_key')

    if not api_key:
        callback(NO_KEY_MSG, None)
        return

    _call_gemini(
        text,
        target_lang=settings.get('target_language'),
        api_key=api_key,
        tone=settings.get('tone'),
        gender=settings.get('gender'),
        callback=callback,
    )
