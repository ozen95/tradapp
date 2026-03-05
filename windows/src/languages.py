LANGUAGES = [
    ('ar',    '🇸🇦', 'العربية',           'Arabic'),
    ('zh-CN', '🇨🇳', '中文（简体）',        'Chinese (Simplified)'),
    ('zh-TW', '🇹🇼', '中文（繁體）',        'Chinese (Traditional)'),
    ('cs',    '🇨🇿', 'Čeština',           'Czech'),
    ('da',    '🇩🇰', 'Dansk',             'Danish'),
    ('nl',    '🇳🇱', 'Nederlands',        'Dutch'),
    ('en',    '🇬🇧', 'English',           'English'),
    ('fi',    '🇫🇮', 'Suomi',             'Finnish'),
    ('fr',    '🇫🇷', 'Français',          'French'),
    ('de',    '🇩🇪', 'Deutsch',           'German'),
    ('el',    '🇬🇷', 'Ελληνικά',          'Greek'),
    ('he',    '🇮🇱', 'עברית',             'Hebrew'),
    ('hi',    '🇮🇳', 'हिन्दी',              'Hindi'),
    ('hu',    '🇭🇺', 'Magyar',            'Hungarian'),
    ('id',    '🇮🇩', 'Bahasa Indonesia',  'Indonesian'),
    ('it',    '🇮🇹', 'Italiano',          'Italian'),
    ('ja',    '🇯🇵', '日本語',             'Japanese'),
    ('ko',    '🇰🇷', '한국어',             'Korean'),
    ('ms',    '🇲🇾', 'Bahasa Melayu',     'Malay'),
    ('no',    '🇳🇴', 'Norsk',             'Norwegian'),
    ('fa',    '🇮🇷', 'فارسی',             'Persian'),
    ('pl',    '🇵🇱', 'Polski',            'Polish'),
    ('pt',    '🇧🇷', 'Português',         'Portuguese'),
    ('ro',    '🇷🇴', 'Română',            'Romanian'),
    ('ru',    '🇷🇺', 'Русский',           'Russian'),
    ('es',    '🇪🇸', 'Español',           'Spanish'),
    ('sv',    '🇸🇪', 'Svenska',           'Swedish'),
    ('th',    '🇹🇭', 'ภาษาไทย',           'Thai'),
    ('tr',    '🇹🇷', 'Türkçe',            'Turkish'),
    ('uk',    '🇺🇦', 'Українська',        'Ukrainian'),
    ('ur',    '🇵🇰', 'اردو',              'Urdu'),
    ('vi',    '🇻🇳', 'Tiếng Việt',        'Vietnamese'),
]


def find_language(lang_id):
    if not lang_id:
        return None
    for lang in LANGUAGES:
        if lang[0].lower() == lang_id.lower():
            return lang
    return None


def get_english_name(lang_id):
    lang = find_language(lang_id)
    return lang[3] if lang else lang_id
