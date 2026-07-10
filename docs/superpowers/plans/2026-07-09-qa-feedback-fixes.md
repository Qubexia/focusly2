# خطة إصلاح ملاحظات QA + كتم الإشعارات

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** إصلاح كل ملاحظات تقرير الـ QA (12 صفحة) وإصلاح خاصية كتم/تقليل الإشعارات التي لا تعمل.

**Architecture:** إصلاحات متوازية عبر Flutter (`focusly/`) و NestJS (`focaly-backend/`): Auth/Tokens أولاً (لأنها تكسر الجلسات والإحصائيات)، ثم Pomodoro completion، ثم Analytics، ثم Planner/Subjects UX، ثم Focus Mode / DND.

**Tech Stack:** Flutter + Dio + SecureStorage · NestJS + MongoDB + BullMQ + FCM · Android NotificationManager (DND)

**Source:** `c:\Users\abdel\Downloads\4_5942550745411756937.pdf` (12 لقطة شاشة معلّقة)

---

## ملخص ملاحظات الـ PDF (مرتبة بالأولوية)

| # | الصفحة | المشكلة | النوع |
|---|--------|---------|-------|
| P0 | 9 | الجلسة تعلق عند 00:00 ولا تُغلق ولا تُضاف للإحصائيات + `Token is invalid or expired` | Bug حرج |
| P0 | 8, 11, 12 | الإحصائيات أصفار / الرسم فارغ / نظرة عامة في البروفايل ناقصة | Bug حرج |
| P0 | — | **كتم الإشعارات لا يعمل** (طلب صريح من المستخدم) | Bug حرج |
| P1 | 2 | إيميل Reset Password يعرض JWT خام بدل رابط | Bug |
| P1 | 1 | فشل Google Sign-In + شكوى تسجيل بالإيميل | Bug / Config |
| P1 | 6 | ضغط "قادم اليوم" يفتح كل المواد بدل المادة نفسها | Bug |
| P2 | 3, 7 | استبدال "مهمة/المهام" بـ "مذاكرة/المذاكرة" + جدول مذاكرة | UX |
| P2 | 4 | إضافة تحديد تاريخ + تكرار بالأيام في نموذج الخطة | Feature |
| P2 | 5 | "هدف يومي" → هدف أسبوعي | Product |
| P2 | 10 | إضافة "الإبقاء على تسجيل الدخول" | Feature |

---

## خريطة الملفات المتأثرة

### Auth / Tokens
- `focaly-backend/src/modules/auth/templates/password-reset.template.ts`
- `focaly-backend/src/modules/auth/auth.service.ts`
- `focaly-backend/src/config/env/app.config.ts`
- `focusly/lib/core/network/api_client.dart`
- `focusly/lib/features/auth/presentation/bloc/auth_bloc.dart`
- `focusly/lib/features/auth/presentation/pages/login_page.dart`
- `focusly/lib/core/services/deep_link_service.dart`
- `focusly/android/app/src/main/AndroidManifest.xml`

### Mute / Focus Mode / DND
- `focusly/lib/features/profile/presentation/pages/settings_page.dart`
- `focusly/lib/features/profile/data/datasources/profile_remote_datasource.dart`
- `focusly/lib/features/auth/data/models/user_model.dart`
- `focusly/lib/core/services/dnd_service.dart`
- `focusly/android/app/src/main/kotlin/com/example/focusly/MainActivity.kt`
- `focaly-backend/src/modules/notifications/workers/notifications.worker.ts`

### Pomodoro / Analytics
- `focusly/lib/features/pomodoro/presentation/cubit/pomodoro_cubit.dart`
- `focusly/lib/features/analytics/**`
- `focusly/lib/features/profile/presentation/pages/profile_page.dart`
- `focaly-backend/src/modules/analytics/analytics.service.ts`
- `focaly-backend/src/modules/analytics/analytics-rollup.service.ts`

### Planner / Subjects / Home
- `focusly/lib/l10n/app_ar.arb`, `app_en.arb`
- `focusly/lib/features/planner/presentation/widgets/create_planned_item_sheet.dart`
- `focusly/lib/features/planner/presentation/widgets/subject_planner_section.dart`
- `focusly/lib/features/home/presentation/pages/home_page.dart`
- `focusly/lib/features/subjects/presentation/pages/subjects_page.dart`
- `focusly/lib/features/subjects/presentation/pages/subject_detail_page.dart`
- `focusly/lib/features/schedules/presentation/widgets/create_schedule_sheet.dart`

---

## تشخيص كتم الإشعارات (الجذر)

هناك **مساران منفصلان** وكلاهما معطوب جزئياً:

### أ) إعدادات "وضع التركيز" (`settings.focusMode`)
1. في `settings_page.dart`: `_focusMode` يبدأ دائماً `false` ولا يُحمَّل من السيرفر في `_load()`.
2. `UserModel` لا يحتوي `focusMode` أصلاً.
3. التبديل يستدعي `PATCH /v1/users/me/settings` بنجاح ظاهرياً، لكن عند إعادة فتح الصفحة يعود OFF.
4. الباكند يحترم `focusMode` فقط أثناء جلسة بومودورو نشطة (`notifications.worker.ts` سطور 66–71) — وهذا صحيح كمنطق سيرفر، لكن الـ UI مضلل.

### ب) كتم الجهاز (DND) أثناء جلسة Premium
1. `pomodoro_page.dart` يمرّر `silenceNotifications: isPremium`.
2. `DndService.enableFocusSilence()` يطلب صلاحية `ACCESS_NOTIFICATION_POLICY` **مرة واحدة فقط** (`dnd_permission_prompted`). لو رفض المستخدم، لن يُطلب مجدداً ولن يُفعَّل الكتم أبداً.
3. لا يوجد feedback للمستخدم عند فشل الصلاحية.
4. iOS: no-op متعمد (لا API عام لـ DND).

---

### Task 1: إصلاح تحميل/حفظ وضع التركيز (كتم إشعارات التطبيق)

**Files:**
- Modify: `focusly/lib/features/auth/data/models/user_model.dart`
- Modify: `focusly/lib/features/profile/data/datasources/profile_remote_datasource.dart`
- Modify: `focusly/lib/features/profile/presentation/pages/settings_page.dart`
- Modify: `focusly/lib/l10n/app_ar.arb`, `app_en.arb`

- [ ] **Step 1: أضف `focusMode` إلى `UserModel`**

```dart
final bool focusMode;
// في fromJson:
focusMode: (json['settings'] is Map
    ? (json['settings']['focusMode'] ?? false)
    : false) as bool,
```

- [ ] **Step 2: حمّل القيمة في Settings**

في `_load()` بعد جلب prefs، اجلب المستخدم الحالي أو أضف endpoint settings read. الأبسط:

```dart
final me = await _dio.get(ApiEndpoints.usersMe);
final settings = me.data['settings'] as Map<String, dynamic>?;
_focusMode = (settings?['focusMode'] ?? false) as bool;
```

أو أضف `getSettings()` في `ProfileRemoteDataSource` يعيد `{ focusMode, notifications, ... }`.

- [ ] **Step 3: عند تفعيل Focus Mode أثناء جلسة نشطة — أكّد أن الـ worker يتخطى FCM**

تحقق يدوياً: فعّل Focus Mode → ابدأ جلسة → أرسل reminder job → يجب ألا يصل Push (يُسجَّل inbox فقط إن وُجد title).

- [ ] **Step 4: حسّن النص في الـ UI**

حدّث subtitle ليوضح السلوك الفعلي:
- AR: `أثناء جلسة التركيز، لن نرسل إشعارات التذكير والسلسلة`
- EN: `During a focus session, reminder and streak pushes are suppressed`

- [ ] **Step 5: Commit**

```bash
git add focusly/lib/features/auth/data/models/user_model.dart focusly/lib/features/profile focusly/lib/l10n
git commit -m "fix: persist and reload focusMode mute setting"
```

---

### Task 2: إصلاح كتم إشعارات الجهاز (DND) أثناء الجلسة

**Files:**
- Modify: `focusly/lib/core/services/dnd_service.dart`
- Modify: `focusly/lib/features/pomodoro/presentation/pages/pomodoro_page.dart`
- Modify: `focusly/android/app/src/main/kotlin/com/example/focusly/MainActivity.kt`

- [ ] **Step 1: أعد طلب الصلاحية إذا لم تُمنح**

في `enableFocusSilence()`: لا تعتمد على `_promptedKey` كحظر دائم. إذا الصلاحية غير ممنوحة، افتح الإعدادات في كل مرة يبدأ فيها المستخدم جلسة مع `silenceNotifications: true` (أو أقصى مرة كل جلسة، مع SnackBar توضيحي).

```dart
Future<bool> enableFocusSilence({bool forcePrompt = true}) async {
  if (!_supported) return false;
  if (await _isPermissionGranted()) {
    final ok = await _channel.invokeMethod<bool>('setDnd', {'enable': true}) ?? false;
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_engagedKey, true);
    }
    return ok;
  }
  if (forcePrompt) {
    await _channel.invokeMethod('openPermissionSettings');
  }
  return false;
}
```

- [ ] **Step 2: أظهر feedback في UI**

بعد `startSession(silenceNotifications: true)`، إذا فشل DND اعرض SnackBar:
`فعّل صلاحية عدم الإزعاج من الإعدادات لكتم إشعارات الجهاز`

- [ ] **Step 3: أضف زر/حالة في إعدادات الجلسة (اختياري)**

Toggle صريح "كتم إشعارات الجهاز" على شاشة البومودورو (Premium) بدل الاعتماد الصامت على `isPremium`.

- [ ] **Step 4: اختبر على Android حقيقي**

1. ابدأ جلسة بدون صلاحية → يجب فتح شاشة Policy Access.
2. امنح الصلاحية → أعد بدء الجلسة → `INTERRUPTION_FILTER_NONE`.
3. أنهِ الجلسة → يعود `INTERRUPTION_FILTER_ALL`.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix: reliably enable Android DND during focus sessions"
```

---

### Task 3: إصلاح إيميل إعادة تعيين كلمة المرور (JWT خام)

**Files:**
- Modify: `focaly-backend/src/config/env/app.config.ts`
- Modify: `focaly-backend/src/modules/auth/auth.service.ts`
- Modify: `focaly-backend/src/modules/auth/templates/password-reset.template.ts`
- Modify: `focusly/lib/core/services/deep_link_service.dart`
- Modify: `focusly/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: أضف `resetPasswordUrl` للـ config**

```ts
resetPasswordUrl: process.env.APP_RESET_PASSWORD_URL ?? '',
```

- [ ] **Step 2: أضف `buildResetPasswordUrl(token)` مثل verify**

```ts
private buildResetPasswordUrl(token: string): string {
  const explicit = this.config.get<string>('app.resetPasswordUrl') ?? '';
  const port = this.config.get<number>('app.port') ?? 5000;
  const base = explicit || `http://localhost:${port}/v1/auth/reset-password`;
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}token=${encodeURIComponent(token)}`;
}
```

واستدعِ القالب بـ URL لا بالـ token الخام.

- [ ] **Step 3: أعد كتابة القالب**

```ts
export function buildPasswordResetEmail(to: string, resetUrl: string): MailMessage {
  return {
    to,
    subject: 'Reset your Focaly password',
    text: `Reset your password: ${resetUrl}`,
    html: `<p>اضغط لإعادة تعيين كلمة المرور:</p>
           <p><a href="${resetUrl}">إعادة تعيين كلمة المرور</a></p>
           <p>أو انسخ الرابط:<br/>${resetUrl}</p>`,
  };
}
```

- [ ] **Step 4: Deep link في التطبيق**

- Intent filter: `zakerly://reset-password?token=...`
- في `DeepLinkService`: وجّه إلى `/reset-password?token=`

- [ ] **Step 5: اختبار يدوي**

`POST /v1/auth/forgot-password` → افتح الإيميل → يجب رابط قابل للنقر → يفتح شاشة تعيين كلمة مرور جديدة.

- [ ] **Step 6: Commit**

```bash
git commit -m "fix: send clickable password-reset link instead of raw JWT"
```

---

### Task 4: إصلاح Refresh Token أثناء الجلسات الطويلة

**Files:**
- Modify: `focusly/lib/core/network/api_client.dart`
- Modify: `focusly/lib/features/auth/data/repositories/auth_repository_impl.dart`

- [ ] **Step 1: طابور انتظار أثناء الـ refresh**

استبدل `if (_isRefreshing) return false;` بطابور Completer:

```dart
Completer<bool>? _refreshCompleter;

Future<bool> _refreshAndRetry(...) async {
  if (_refreshCompleter != null) {
    final ok = await _refreshCompleter!.future;
    if (!ok) return false;
    // retry request with new token
    ...
  }
  _refreshCompleter = Completer<bool>();
  try {
    final refreshed = await _attemptRefresh();
    _refreshCompleter!.complete(refreshed);
    ...
  } finally {
    _refreshCompleter = null;
  }
}
```

- [ ] **Step 2: Refresh استباقي**

عند بدء جلسة بومودورو (أو كل 10 دقائق أثناء التشغيل)، استدعِ `refreshSessionTokens()` إذا بقي أقل من 2 دقيقة على صلاحية الـ access token.

- [ ] **Step 3: `tryAutoLogin` يحاول refresh قبل الفشل**

```dart
try {
  return await fetchCurrentUser();
} catch (_) {
  final ok = await refreshSessionTokens();
  if (!ok) return null;
  return await fetchCurrentUser();
}
```

- [ ] **Step 4: Commit**

```bash
git commit -m "fix: queue concurrent 401 refreshes and refresh before long sessions"
```

---

### Task 5: إصلاح تعليق جلسة البومودورو عند الانتهاء

**Files:**
- Modify: `focusly/lib/features/pomodoro/presentation/cubit/pomodoro_cubit.dart`
- Modify: `focusly/lib/features/pomodoro/presentation/pages/pomodoro_page.dart`

- [ ] **Step 1: في `completeSession` catch — صفّر الحالة دائماً**

```dart
} catch (e) {
  _autoCompleting = false;
  // أبقِ activeSession لكن اعرض Retry؛ أو abort محلي بعد N محاولات
  emit(state.copyWith(
    isSaving: false,
    feedbackType: PomodoroFeedbackType.error,
    feedbackMessage: ...,
  ));
}
```

تأكد أن `_autoCompleting` يُصفَّر في **كل** مسارات الخروج (success + error).

- [ ] **Step 2: UI fallback عند `remainingSeconds == 0 && activeSession != null`**

أظهر زر "إنهاء وإعادة المحاولة" يستدعي `completeSession()` مجدداً، وزر "إلغاء الجلسة" يستدعي `abortSession()`.

- [ ] **Step 3: قبل complete — refresh token**

```dart
await ApiClient.refreshSessionTokensIfNeeded();
await _repository.completeSession(...);
```

- [ ] **Step 4: اختبار**

جلسة قصيرة (1 دقيقة) → يجب أن تُغلق وتظهر في الإحصائيات. جلسة بعد انتهاء access token → refresh ثم complete بنجاح.

- [ ] **Step 5: Commit**

```bash
git commit -m "fix: unstick pomodoro completion and retry after auth errors"
```

---

### Task 6: إصلاح الإحصائيات + نظرة عامة البروفايل

**Files:**
- Modify: `focaly-backend/src/modules/analytics/analytics.service.ts`
- Modify: `focaly-backend/src/modules/analytics/analytics-rollup.service.ts` (أو handler على `PomodoroCompletedEvent`)
- Modify: `focusly/lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `focusly/lib/features/analytics/presentation/bloc/analytics_cubit.dart`

- [ ] **Step 1: Backend — حدّث الـ rollup فورياً عند اكتمال الجلسة**

في handler لـ `PomodoroCompletedEvent`: استدعِ `analyticsRepo.upsertDay(userId, date, focusMinutes, ...)`.

- [ ] **Step 2: Backend — املأ `dailyFocus` لنطاقات > 7 أيام**

لا تُرجع `dailyFocus: []` للشهر/السنة؛ اجلب من rollup أو جمّع من pomodoro.

- [ ] **Step 3: `performance()` يستخدم بيانات حية للأسبوع الحالي**

لا تعتمد فقط على rollup الليلي لليوم الحالي.

- [ ] **Step 4: Profile — احذف الرقم الثابت `'24'`**

اجلب من `PomodoroRepository` / analytics summary:
- جلسات التركيز
- السلسلة
- النقاط (`user.totalPoints`)

- [ ] **Step 5: Frontend chart — لا تُصفّر عند خطأ Premium للنطاقات المسموحة**

- [ ] **Step 6: Commit**

```bash
git commit -m "fix: real-time analytics rollup and profile overview stats"
```

---

### Task 7: تنقل "قادم اليوم" إلى المادة الصحيحة

**Files:**
- Modify: `focusly/lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: مرّر `subjectId` لكل chip**

```dart
onTap: () {
  final id = task.subjectId;
  if (id != null && id.isNotEmpty) {
    context.push('/subjects/$id');
  } else {
    context.push('/subjects');
  }
},
```

نفس المنطق لـ schedules: `/subjects/${schedule.subjectId}`.

- [ ] **Step 2: اختبار**

من Home اضغط بطاقة مادة محددة → يجب فتح `SubjectDetail` لتلك المادة.

- [ ] **Step 3: Commit**

```bash
git commit -m "fix: navigate upcoming chips to the related subject"
```

---

### Task 8: استبدال "مهمة" بـ "مذاكرة" + جدول مذاكرة في تفاصيل المادة

**Files:**
- Modify: `focusly/lib/l10n/app_ar.arb`, `app_en.arb`
- Modify: `focusly/lib/features/planner/presentation/widgets/subject_planner_section.dart`
- Modify: `focusly/lib/features/subjects/presentation/pages/subject_detail_page.dart`
- Reuse: `focusly/lib/features/schedules/presentation/widgets/create_schedule_sheet.dart`

- [ ] **Step 1: Label-only rename (بدون كسر الـ API `task`)**

```json
"plannerTypeTask": "مذاكرة",
"plannerTabTasks": "المذاكرة",
"homeQuickAddTaskLabel": "مذاكرة"
```

EN: `"Study"` / `"Studying"`. ثم `flutter gen-l10n`.

- [ ] **Step 2: في Subject Detail أضف قسم جدول مذاكرة**

فوق أو بجانب الـ planner: قائمة schedules للمادة + زر "إضافة جدول مذاكرة" يفتح `CreateScheduleSheet` مع `lockedSubjectId: subject.id`.

- [ ] **Step 3: Commit**

```bash
git commit -m "feat: rename task to study and add subject study schedules"
```

---

### Task 9: تاريخ + تكرار في نموذج إضافة خطة

**Files:**
- Modify: `focusly/lib/features/planner/presentation/widgets/create_planned_item_sheet.dart`
- Modify: `focusly/lib/features/planner/presentation/bloc/planner_cubit.dart`
- Modify: `focusly/lib/features/planner/data/datasources/planner_remote_datasource.dart`
- Optional backend: `planned-item.schema.ts` إن احتجنا `daysOfWeek`

- [ ] **Step 1: أضف DatePicker بجانب TimePicker**

```dart
await showDatePicker(...);
_selectedDate = picked;
```

اعرض التاريخ المختار في صف "تحديد التاريخ والوقت".

- [ ] **Step 2: أرسل `recurrence` الموجود أصلاً في الباكند**

UI: `مرة واحدة` / `يومياً` / `أسبوعياً` → `once` | `daily` | `weekly`.

- [ ] **Step 3 (إن طُلب تكرار بأيام محددة):**

إما:
- استخدم Study Schedule (لديه `daysOfWeek`) للخطط المتكررة، أو
- وسّع PlannedItem بـ `daysOfWeek: number[]`.

القرار الموصى به: للتكرار بالأيام وجّه المستخدم لـ "جدول مذاكرة" (Task 8) وأبقِ planned items لـ once/daily/weekly البسيط.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add date and recurrence to create-plan sheet"
```

---

### Task 10: الهدف اليومي → أسبوعي

**Files:**
- Modify: `focusly/lib/features/subjects/presentation/pages/subjects_page.dart`
- Modify: `focusly/lib/l10n/app_ar.arb`, `app_en.arb`
- Modify: `focusly/lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: في Create Subject Sheet انسخ منطق Edit**

من `subject_detail_page.dart`: toggle `goalType` daily/weekly + `goalDays` picker. الافتراضي الجديد: `weekly`.

- [ ] **Step 2: حدّث النصوص**

```json
"subjectsDailyTarget": "الهدف",
"subjectsDailyTargetLabel": "هدف {minutes} دقيقة",
"subjectsWeeklyTargetLabel": "هدف أسبوعي {minutes} دقيقة"
```

اعرض حسب `goalType`.

- [ ] **Step 3: Home لا يجمع أهداف أسبوعية كأنها يومية**

احسب الشريط اليومي فقط للمواد `goalType == daily`، أو اعرض هدف أسبوعي منفصل.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat: default subject goals to weekly and fix labels"
```

---

### Task 11: Google Sign-In + تسجيل بالإيميل + Remember Me

**Files:**
- Modify: `focusly/lib/features/auth/presentation/bloc/auth_bloc.dart`
- Modify: `focusly/lib/features/auth/presentation/pages/login_page.dart`
- Config: `google-services.json`, `GOOGLE_CLIENT_ID`, `DevApiConfig`

- [ ] **Step 1: Google — أضف `serverClientId`**

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: const String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '<WEB_CLIENT_ID>',
  ),
);
```

يجب أن يطابق `GOOGLE_CLIENT_ID` في الباكند. تأكد من وجود `google-services.json` و package `com.example.focusly`.

- [ ] **Step 2: Email login — رسائل أوضح**

إذا الحساب Google-only (`passwordHash` null)، اعرض: `هذا الحساب مسجّل عبر Google. سجّل الدخول بـ Google أو عيّن كلمة مرور.`

تحقق أيضاً أن `DevApiConfig.physicalDeviceBaseUrl` يشير لنفس بيئة بيانات المستخدم.

- [ ] **Step 3: Remember Me checkbox**

- افتراضي: ON (السلوك الحالي — حفظ في SecureStorage).
- OFF: احفظ التوكن في الذاكرة فقط وامسحه عند إغلاق التطبيق / الخلفية.

مرّر `rememberMe` عبر `AuthLoginRequested`.

- [ ] **Step 4: Commit**

```bash
git commit -m "fix: Google OAuth wiring and add remember-me login option"
```

---

## ترتيب التنفيذ المقترح

```
Task 4 (token refresh) ─┬─► Task 5 (pomodoro hang) ─► Task 6 (analytics)
Task 1 + 2 (mute) ──────┤
Task 3 (reset email) ───┘
Task 7 (home nav)          } يمكن بالتوازي بعد P0
Task 8, 9, 10 (UX)         }
Task 11 (auth UX/config)   } يحتاج أسرار Firebase من الفريق
```

## خطة الاختبار الشاملة

1. **Mute:** Settings Focus Mode ON → reload page → يبقى ON → ابدأ جلسة → لا يصل FCM reminder.
2. **DND Android:** امنح Policy Access → ابدأ جلسة Premium → إشعارات النظام مكتومة → أنهِ → تعود.
3. **Reset password:** forgot → إيميل فيه رابط → يفتح الشاشة → كلمة مرور جديدة تعمل.
4. **Pomodoro:** جلسة 1 د → تُغلق وحدها → تظهر دقائق في Analytics + Profile.
5. **Token:** اترك التطبيق 20 دقيقة داخل جلسة → Pause/Complete بدون خطأ JWT.
6. **Home chip:** يفتح المادة الصحيحة.
7. **Labels:** مهمة → مذاكرة في كل الشاشات.
8. **Plan form:** تاريخ + تكرار يُحفظان.
9. **Weekly goal:** مادة جديدة افتراضياً أسبوعي.
10. **Google + Remember Me:** يعملان حسب الإعداد.

## تغطية الـ Spec

| ملاحظة PDF / طلب | Task |
|------------------|------|
| كتم الإشعارات لا يعمل | 1, 2 |
| JWT في إيميل الريست | 3 |
| Token expired / جلسة تعلق | 4, 5 |
| إحصائيات فارغة / بروفايل | 5, 6 |
| قادم اليوم → مادة خاطئة | 7 |
| مهمة → مذاكرة + جدول | 8 |
| تاريخ + تكرار | 9 |
| هدف يومي → أسبوعي | 10 |
| Google / إيميل / Remember Me | 11 |

---

**بعد اعتماد الخطة:** اختر أسلوب التنفيذ:

1. **Subagent-Driven** — وكيل منفصل لكل Task مع مراجعة بين المهام
2. **Inline Execution** — تنفيذ متسلسل في نفس الجلسة مع checkpoints
