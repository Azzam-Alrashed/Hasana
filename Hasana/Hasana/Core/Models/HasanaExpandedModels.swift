import Foundation
import SwiftUI

// MARK: - Dhikr & Tasbih Models
struct DhikrPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var arabicName: String
    var englishName: String
    var defaultLimit: Int
    
    init(id: UUID = UUID(), arabicName: String, englishName: String, defaultLimit: Int) {
        self.id = id
        self.arabicName = arabicName
        self.englishName = englishName
        self.defaultLimit = defaultLimit
    }
    
    func name(for language: HasanaLanguage) -> String {
        language == .arabic ? arabicName : englishName
    }
    
    static let defaults: [DhikrPreset] = [
        DhikrPreset(arabicName: "سُبْحَانَ اللَّهِ", englishName: "Subhan Allah", defaultLimit: 33),
        DhikrPreset(arabicName: "الْحَمْدُ لِلَّهِ", englishName: "Alhamdulillah", defaultLimit: 33),
        DhikrPreset(arabicName: "اللَّهُ أَكْبَرُ", englishName: "Allahu Akbar", defaultLimit: 34),
        DhikrPreset(arabicName: "أَسْتَغْفِرُ اللَّهَ", englishName: "Astaghfirullah", defaultLimit: 100),
        DhikrPreset(arabicName: "لَا إِلٰهَ إِلَّا اللَّهُ", englishName: "La ilaha illa Allah", defaultLimit: 100),
        DhikrPreset(arabicName: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ", englishName: "Shalawat Nabi", defaultLimit: 100)
    ]
}

// MARK: - Quran Tracker & Journal Models
struct QuranReflection: Identifiable, Codable, Hashable {
    let id: UUID
    var surahName: String
    var verseNumber: String
    var arabicText: String?
    var reflectionText: String
    var date: Date
    
    init(id: UUID = UUID(), surahName: String, verseNumber: String, arabicText: String? = nil, reflectionText: String, date: Date = Date()) {
        self.id = id
        self.surahName = surahName
        self.verseNumber = verseNumber
        self.arabicText = arabicText
        self.reflectionText = reflectionText
        self.date = date
    }
}

struct KhatmGoal: Codable, Hashable {
    var targetDays: Int
    var startPage: Int
    var currentPage: Int
    var startDate: Date
    var isCompleted: Bool
    
    init(targetDays: Int = 30, startPage: Int = 1, currentPage: Int = 1, startDate: Date = Date(), isCompleted: Bool = false) {
        self.targetDays = targetDays
        self.startPage = startPage
        self.currentPage = currentPage
        self.startDate = startDate
        self.isCompleted = isCompleted
    }
    
    var totalPagesLeft: Int {
        max(604 - currentPage, 0)
    }
    
    var daysElapsed: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let now = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: start, to: now)
        return max(components.day ?? 0, 0)
    }
    
    var daysRemaining: Int {
        max(targetDays - daysElapsed, 1)
    }
    
    var pagesPerDayRequired: Double {
        let remaining = Double(daysRemaining)
        return Double(totalPagesLeft) / remaining
    }
    
    var progressFraction: Double {
        Double(currentPage) / 604.0
    }
}

// MARK: - Sunnah Tracker Models
struct SunnahDayRecord: Codable, Hashable {
    var dateKey: String // YYYY-MM-DD
    var performedRawatib: [String] // "fajr_sunnah", "dhuhr_before", etc.
    var performedDuha: Bool
    var performedQiyam: Bool
    var performedWitr: Bool
    var fastedToday: Bool
    var sadaqahLogged: Bool
    var sadaqahNote: String?
    
    init(
        dateKey: String,
        performedRawatib: [String] = [],
        performedDuha: Bool = false,
        performedQiyam: Bool = false,
        performedWitr: Bool = false,
        fastedToday: Bool = false,
        sadaqahLogged: Bool = false,
        sadaqahNote: String? = nil
    ) {
        self.dateKey = dateKey
        self.performedRawatib = performedRawatib
        self.performedDuha = performedDuha
        self.performedQiyam = performedQiyam
        self.performedWitr = performedWitr
        self.fastedToday = fastedToday
        self.sadaqahLogged = sadaqahLogged
        self.sadaqahNote = sadaqahNote
    }
}

// MARK: - Prayer Settings
enum CalculationMethod: String, Codable, CaseIterable, Identifiable {
    case ummAlQura = "Umm al-Qura (Makkah)"
    case muslimWorldLeague = "Muslim World League"
    case egyptSurvey = "Egyptian General Authority of Survey"
    case isna = "ISNA (North America)"
    case karachi = "University of Islamic Sciences, Karachi"
    
    var id: String { rawValue }
    
    func title(for language: HasanaLanguage) -> String {
        switch (self, language) {
        case (.ummAlQura, .arabic): "أم القرى (مكة المكرمة)"
        case (.ummAlQura, .english): "Umm al-Qura (Makkah)"
        case (.muslimWorldLeague, .arabic): "رابطة العالم الإسلامي"
        case (.muslimWorldLeague, .english): "Muslim World League"
        case (.egyptSurvey, .arabic): "الهيئة المصرية العامة للمساحة"
        case (.egyptSurvey, .english): "Egyptian Survey Authority"
        case (.isna, .arabic): "الجمعية الإسلامية لأمريكا الشمالية (ISNA)"
        case (.isna, .english): "ISNA (North America)"
        case (.karachi, .arabic): "جامعة العلوم الإسلامية بكراتشي"
        case (.karachi, .english): "University of Karachi"
        }
    }
}

struct PrayerSettings: Codable, Hashable {
    var method: CalculationMethod
    var useHanafiAsr: Bool
    var latitude: Double
    var longitude: Double
    var cityName: String
    var enableAthanNotifications: Bool
    
    init(
        method: CalculationMethod = .ummAlQura,
        useHanafiAsr: Bool = false,
        latitude: Double = 21.4225, // default Makkah
        longitude: Double = 39.8262,
        cityName: String = "Makkah",
        enableAthanNotifications: Bool = true
    ) {
        self.method = method
        self.useHanafiAsr = useHanafiAsr
        self.latitude = latitude
        self.longitude = longitude
        self.cityName = cityName
        self.enableAthanNotifications = enableAthanNotifications
    }
}

// MARK: - Islamic Hub & Hisn al-Muslim (Duas) Models
struct DuaItem: Identifiable, Codable, Hashable {
    let id: UUID
    var categoryAr: String
    var categoryEn: String
    var titleAr: String
    var titleEn: String
    var arabic: String
    var translationAr: String?
    var translationEn: String?
    var transliteration: String?
    var isBookmarked: Bool
    var isCustom: Bool
    
    init(
        id: UUID = UUID(),
        categoryAr: String,
        categoryEn: String,
        titleAr: String,
        titleEn: String,
        arabic: String,
        translationAr: String? = nil,
        translationEn: String? = nil,
        transliteration: String? = nil,
        isBookmarked: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = id
        self.categoryAr = categoryAr
        self.categoryEn = categoryEn
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.arabic = arabic
        self.translationAr = translationAr
        self.translationEn = translationEn
        self.transliteration = transliteration
        self.isBookmarked = isBookmarked
        self.isCustom = isCustom
    }
    
    func title(for language: HasanaLanguage) -> String {
        language == .arabic ? titleAr : titleEn
    }
    
    func category(for language: HasanaLanguage) -> String {
        language == .arabic ? categoryAr : categoryEn
    }
    
    func translation(for language: HasanaLanguage) -> String? {
        language == .arabic ? translationAr : translationEn
    }
    
    static let defaults: [DuaItem] = [
        DuaItem(
            categoryAr: "الأذكار اليومية",
            categoryEn: "Daily Adhkar",
            titleAr: "دعاء الاستيقاظ من النوم",
            titleEn: "Dua upon Waking Up",
            arabic: "الْحَمْدُ للهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
            translationAr: "الحمد لله الذي رد إلينا روحنا بعد الموت وإليه نبعث يوم القيامة.",
            translationEn: "Praise is to Allah Who gave us life after He had caused us to die and unto Him is the resurrection.",
            transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilaihin-nushur."
        ),
        DuaItem(
            categoryAr: "الأذكار اليومية",
            categoryEn: "Daily Adhkar",
            titleAr: "دعاء لبس الثوب",
            titleEn: "Dua for Wearing Clothes",
            arabic: "الْحَمْدُ للهِ الَّذِي كَسَانِي هَذَا الثَّوْبَ وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ",
            translationAr: "الحمد لله الذي وهبني هذا الملبس ورزقنيه بلا حول مني ولا قوة.",
            translationEn: "Praise is to Allah Who has clothed me with this garment and provided it for me without any might or power on my part.",
            transliteration: "Alhamdu lillahil-ladhi kasani hadha-thawba wa razaqanihi min ghayri hawlin minni wa la quwwah."
        ),
        DuaItem(
            categoryAr: "الصلاة والوضوء",
            categoryEn: "Prayer & Wudu",
            titleAr: "دعاء دخول المسجد",
            titleEn: "Dua for Entering the Mosque",
            arabic: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ",
            translationAr: "اللهم يسر لي أبواب رحمتك وفضلك.",
            translationEn: "O Allah, open the gates of Your mercy for me.",
            transliteration: "Allahummaf-tah li abwaba rahmatik."
        ),
        DuaItem(
            categoryAr: "الصلاة والوضوء",
            categoryEn: "Prayer & Wudu",
            titleAr: "دعاء الخروج من المسجد",
            titleEn: "Dua for Leaving the Mosque",
            arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ",
            translationAr: "اللهم إني أسألك من جودك ورزقك الحلال.",
            translationEn: "O Allah, I ask You from Your bounty.",
            transliteration: "Allahumma inni as'aluka min fadlik."
        ),
        DuaItem(
            categoryAr: "الاستغفار والتوبة",
            categoryEn: "Forgiveness & Repentance",
            titleAr: "سيد الاستغفار",
            titleEn: "Master of Forgiveness (Sayyid al-Istighfar)",
            arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
            translationAr: "اللهم أنت ربي لا إله إلا أنت، أنشأتني وأنا عبدك المطيع لعهدك ووعدك بقدر ما أستطيع. أعوذ بك من شر أعمالي، وأعترف بنعمك علي وبذنوبي، فاغفر لي فإنه لا يغفر الذنوب إلا أنت.",
            translationEn: "O Allah, You are my Lord, there is no deity except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your grace upon me and I acknowledge my sin, so forgive me, for indeed, none forgives sins except You.",
            transliteration: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu. A'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u bidhanbi faghfir li fa'innahu la yaghfiru-dhunuba illa ant."
        ),
        DuaItem(
            categoryAr: "السفر والترحال",
            categoryEn: "Travel & Protection",
            titleAr: "دعاء السفر",
            titleEn: "Dua for Travel",
            arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ",
            translationAr: "سبحان الله الذي يسر لنا هذا المركوب وما كنا نطيق تسخيره لولا فضله، وإنا لراجعون إلى ربنا في الآخرة.",
            translationEn: "Glory is to Him Who has subjected this to us, and we were not capable of it on our own, and indeed, to our Lord we will return.",
            transliteration: "Subhanal-ladhi sakhkhara lana hadha wa ma kunna lahu muqrinina wa inna ila Rabbina lamunqalibun."
        ),
        DuaItem(
            categoryAr: "الضيق والقلق",
            categoryEn: "Distress & Anxiety",
            titleAr: "دعاء الكرب",
            titleEn: "Dua for Relief of Anxiety",
            arabic: "لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ السَّمَوَاتِ وَرَبُّ الْأَرْضِ وَرَبُّ الْعَرْشِ الْكَرِيمِ",
            translationAr: "لا معبود بحق إلا الله ذو العظمة والصفح الكبير، لا معبود بحق إلا الله مالك العرش العظيم، لا معبود بحق إلا الله مالك السموات والأرض والعرش الكريم النبيل.",
            translationEn: "There is no deity except Allah, the All-Great, the All-Clement. There is no deity except Allah, Lord of the Magnificent Throne. There is no deity except Allah, Lord of the heavens and Lord of the earth and Lord of the Noble Throne.",
            transliteration: "La ilaha illallahul-'Azimul-Halim, la ilaha illallahu Rabbul-'Arshil-'Azim, la ilaha illallahu Rabbus-samawati wa Rabbul-ardi wa Rabbul-'Arshil-Karim."
        )
    ]
}

// MARK: - Custom Spiritual Habits Tracker
struct SpiritualHabit: Identifiable, Codable, Hashable {
    let id: UUID
    var titleAr: String
    var titleEn: String
    var frequency: String // "daily" or "weekly"
    var targetCount: Int
    var icon: String
    var colorHex: String
    var isLinkedToGarden: Bool
    var gardenPracticeID: String? // Optional link to a garden plant (e.g. .witr, .quran, etc.)
    var creationDate: Date
    
    init(
        id: UUID = UUID(),
        titleAr: String,
        titleEn: String,
        frequency: String = "daily",
        targetCount: Int = 1,
        icon: String = "heart.fill",
        colorHex: String = "#E9C883",
        isLinkedToGarden: Bool = false,
        gardenPracticeID: String? = nil,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.frequency = frequency
        self.targetCount = targetCount
        self.icon = icon
        self.colorHex = colorHex
        self.isLinkedToGarden = isLinkedToGarden
        self.gardenPracticeID = gardenPracticeID
        self.creationDate = creationDate
    }
    
    func title(for language: HasanaLanguage) -> String {
        language == .arabic ? titleAr : titleEn
    }
    
    var themeColor: Color {
        Color(hex: colorHex)
    }
    
    static let defaults: [SpiritualHabit] = [
        SpiritualHabit(
            titleAr: "صلاة الجماعة في المسجد",
            titleEn: "Congregation at Mosque",
            frequency: "daily",
            targetCount: 5,
            icon: "building.2.fill",
            colorHex: "#D5A754",
            isLinkedToGarden: true,
            gardenPracticeID: "fard"
        ),
        SpiritualHabit(
            titleAr: "قراءة صفحة من التفسير",
            titleEn: "Read Tafsir Page",
            frequency: "daily",
            targetCount: 1,
            icon: "book.fill",
            colorHex: "#5F6596",
            isLinkedToGarden: true,
            gardenPracticeID: "quran"
        ),
        SpiritualHabit(
            titleAr: "الاستغفار اليومي",
            titleEn: "Daily Istighfar",
            frequency: "daily",
            targetCount: 100,
            icon: "sparkles",
            colorHex: "#9A6234",
            isLinkedToGarden: true,
            gardenPracticeID: "adhkar"
        ),
        SpiritualHabit(
            titleAr: "التصدق بابتسامة أو عمل صالح",
            titleEn: "Smile or Good Deed",
            frequency: "daily",
            targetCount: 1,
            icon: "heart.fill",
            colorHex: "#706086",
            isLinkedToGarden: true,
            gardenPracticeID: "witr"
        )
    ]
}

struct HabitLog: Identifiable, Codable, Hashable {
    let id: UUID
    var habitID: UUID
    var count: Int
    var dateKey: String // YYYY-MM-DD
    
    init(id: UUID = UUID(), habitID: UUID, count: Int, dateKey: String) {
        self.id = id
        self.habitID = habitID
        self.count = count
        self.dateKey = dateKey
    }
}

// MARK: - Islamic Events & Calendar Models
struct IslamicEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var titleAr: String
    var titleEn: String
    var hijriMonth: Int // 1-indexed (1: Muharram, 9: Ramadan, 12: Dhu al-Hijjah)
    var hijriDay: Int
    var descriptionAr: String
    var descriptionEn: String
    var isFastingRecommended: Bool
    
    init(
        id: UUID = UUID(),
        titleAr: String,
        titleEn: String,
        hijriMonth: Int,
        hijriDay: Int,
        descriptionAr: String,
        descriptionEn: String,
        isFastingRecommended: Bool = false
    ) {
        self.id = id
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.hijriMonth = hijriMonth
        self.hijriDay = hijriDay
        self.descriptionAr = descriptionAr
        self.descriptionEn = descriptionEn
        self.isFastingRecommended = isFastingRecommended
    }
    
    func title(for language: HasanaLanguage) -> String {
        language == .arabic ? titleAr : titleEn
    }
    
    func description(for language: HasanaLanguage) -> String {
        language == .arabic ? descriptionAr : descriptionEn
    }
    
    static let defaults: [IslamicEvent] = [
        IslamicEvent(
            titleAr: "رأس السنة الهجرية",
            titleEn: "Hijri New Year",
            hijriMonth: 1,
            hijriDay: 1,
            descriptionAr: "بداية العام الهجري الجديد ذكرى الهجرة النبوية المباركة.",
            descriptionEn: "Beginning of the new Islamic year, marking the Prophet's migration to Madinah."
        ),
        IslamicEvent(
            titleAr: "يوم عاشوراء",
            titleEn: "Day of Ashura",
            hijriMonth: 1,
            hijriDay: 10,
            descriptionAr: "اليوم العاشر من محرم، يندب صيامه شكراً لله على نجاة موسى عليه السلام.",
            descriptionEn: "The 10th of Muharram, fasting is recommended to thank Allah for saving Prophet Musa.",
            isFastingRecommended: true
        ),
        IslamicEvent(
            titleAr: "المولد النبوي الشريف",
            titleEn: "Prophet's Birthday (Mawlid)",
            hijriMonth: 3,
            hijriDay: 12,
            descriptionAr: "ذكرى مولد نبي الهدى محمد صلى الله عليه وسلم.",
            descriptionEn: "Commemoration of the birth of Prophet Muhammad (peace be upon him)."
        ),
        IslamicEvent(
            titleAr: "ليلة الإسراء والمعراج",
            titleEn: "Isra & Mi'raj",
            hijriMonth: 7,
            hijriDay: 27,
            descriptionAr: "ذكرى معجزة الإسراء والمعراج وفرض الصلوات الخمس.",
            descriptionEn: "Commemoration of the Prophet's miraculous night journey and ascension to the heavens."
        ),
        IslamicEvent(
            titleAr: "بداية شهر رمضان المبارك",
            titleEn: "First Day of Ramadan",
            hijriMonth: 9,
            hijriDay: 1,
            descriptionAr: "بداية شهر الصيام والقيام وتلاوة القرآن.",
            descriptionEn: "First day of the holy month of fasting, prayer, and Quran recitation.",
            isFastingRecommended: true
        ),
        IslamicEvent(
            titleAr: "ليلة القدر (التحري)",
            titleEn: "Laylat al-Qadr (Search)",
            hijriMonth: 9,
            hijriDay: 27,
            descriptionAr: "ليلة القدر خير من ألف شهر، يتحرى قيامها ودعاؤها.",
            descriptionEn: "The Night of Power, better than a thousand months. Seek it in the last ten nights of Ramadan."
        ),
        IslamicEvent(
            titleAr: "عيد الفطر السعيد",
            titleEn: "Eid al-Fitr",
            hijriMonth: 10,
            hijriDay: 1,
            descriptionAr: "عيد الفطر بعد إتمام صيام شهر رمضان المبارك.",
            descriptionEn: "Islamic holiday celebrating the conclusion of the Ramadan fasting month."
        ),
        IslamicEvent(
            titleAr: "يوم عرفة",
            titleEn: "Day of Arafah",
            hijriMonth: 12,
            hijriDay: 9,
            descriptionAr: "أفضل أيام السنة، يشرع صيامه لغير الحاج ويكفر سنتين.",
            descriptionEn: "The pinnacle day of Hajj. Fasting is highly recommended for non-pilgrims.",
            isFastingRecommended: true
        ),
        IslamicEvent(
            titleAr: "عيد الأضحى المبارك",
            titleEn: "Eid al-Adha",
            hijriMonth: 12,
            hijriDay: 10,
            descriptionAr: "عيد الأضحى المبارك وذكرى تضحية نبينا إبراهيم عليه السلام.",
            descriptionEn: "Festival of Sacrifice, celebrating the completion of the pilgrimage of Hajj."
        )
    ]
}

