import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HR System'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Log in with fingerprint'**
  String get loginWithBiometrics;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get checkOut;

  /// No description provided for @totalEmployees.
  ///
  /// In en, this message translates to:
  /// **'Total employees'**
  String get totalEmployees;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @sections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sections;

  /// No description provided for @presentToday.
  ///
  /// In en, this message translates to:
  /// **'Present today'**
  String get presentToday;

  /// No description provided for @lateToday.
  ///
  /// In en, this message translates to:
  /// **'Late today'**
  String get lateToday;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get pendingApprovals;

  /// No description provided for @bySection.
  ///
  /// In en, this message translates to:
  /// **'By section'**
  String get bySection;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @loan.
  ///
  /// In en, this message translates to:
  /// **'Loan / advance'**
  String get loan;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @monthlyHours.
  ///
  /// In en, this message translates to:
  /// **'Monthly hours'**
  String get monthlyHours;

  /// No description provided for @mySalary.
  ///
  /// In en, this message translates to:
  /// **'My salary'**
  String get mySalary;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get locating;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in successfully'**
  String get checkedIn;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out successfully'**
  String get checkedOut;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericError;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get attendanceHistory;

  /// No description provided for @recordForEmployee.
  ///
  /// In en, this message translates to:
  /// **'Record for employee'**
  String get recordForEmployee;

  /// No description provided for @employeeDetail.
  ///
  /// In en, this message translates to:
  /// **'Employee details'**
  String get employeeDetail;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit employee'**
  String get editEmployee;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @remainingPapers.
  ///
  /// In en, this message translates to:
  /// **'Remaining papers'**
  String get remainingPapers;

  /// No description provided for @leaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave requests'**
  String get leaveRequests;

  /// No description provided for @loanRequests.
  ///
  /// In en, this message translates to:
  /// **'Loan requests'**
  String get loanRequests;

  /// No description provided for @resignation.
  ///
  /// In en, this message translates to:
  /// **'Resignation'**
  String get resignation;

  /// No description provided for @shiftChange.
  ///
  /// In en, this message translates to:
  /// **'Shift change'**
  String get shiftChange;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily report'**
  String get dailyReport;

  /// No description provided for @periodReport.
  ///
  /// In en, this message translates to:
  /// **'Period report'**
  String get periodReport;

  /// No description provided for @selfService.
  ///
  /// In en, this message translates to:
  /// **'Self-service'**
  String get selfService;

  /// No description provided for @leaveBalances.
  ///
  /// In en, this message translates to:
  /// **'Leave balances'**
  String get leaveBalances;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @performanceReview.
  ///
  /// In en, this message translates to:
  /// **'Performance review'**
  String get performanceReview;

  /// No description provided for @recruitment.
  ///
  /// In en, this message translates to:
  /// **'Recruitment'**
  String get recruitment;

  /// No description provided for @jobVacancies.
  ///
  /// In en, this message translates to:
  /// **'Job vacancies'**
  String get jobVacancies;

  /// No description provided for @candidates.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidates;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @compensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get compensation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @firstNameAr.
  ///
  /// In en, this message translates to:
  /// **'First name (Arabic)'**
  String get firstNameAr;

  /// No description provided for @lastNameAr.
  ///
  /// In en, this message translates to:
  /// **'Last name (Arabic)'**
  String get lastNameAr;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire date'**
  String get hireDate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get maritalStatus;

  /// No description provided for @hasMobile.
  ///
  /// In en, this message translates to:
  /// **'Has mobile phone'**
  String get hasMobile;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic salary'**
  String get basicSalary;

  /// No description provided for @medicalInsurance.
  ///
  /// In en, this message translates to:
  /// **'Medical insurance'**
  String get medicalInsurance;

  /// No description provided for @socialInsurance.
  ///
  /// In en, this message translates to:
  /// **'Social insurance'**
  String get socialInsurance;

  /// No description provided for @employmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get employmentStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @resigned.
  ///
  /// In en, this message translates to:
  /// **'Resigned'**
  String get resigned;

  /// No description provided for @terminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get terminated;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get selectEmployee;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @mainCode.
  ///
  /// In en, this message translates to:
  /// **'Main code'**
  String get mainCode;

  /// No description provided for @subCode.
  ///
  /// In en, this message translates to:
  /// **'Sub-code'**
  String get subCode;

  /// No description provided for @fullCode.
  ///
  /// In en, this message translates to:
  /// **'Full code'**
  String get fullCode;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameAr;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @geofenceRadius.
  ///
  /// In en, this message translates to:
  /// **'Geofence radius (meters)'**
  String get geofenceRadius;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get workingHours;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get workingDays;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total hours'**
  String get totalHours;

  /// No description provided for @lateCount.
  ///
  /// In en, this message translates to:
  /// **'Late count'**
  String get lateCount;

  /// No description provided for @lateMinutes.
  ///
  /// In en, this message translates to:
  /// **'Late minutes'**
  String get lateMinutes;

  /// No description provided for @overtimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Overtime minutes'**
  String get overtimeMinutes;

  /// No description provided for @overtimeHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime hours'**
  String get overtimeHours;

  /// No description provided for @presentDays.
  ///
  /// In en, this message translates to:
  /// **'Present days'**
  String get presentDays;

  /// No description provided for @absentDays.
  ///
  /// In en, this message translates to:
  /// **'Absent days'**
  String get absentDays;

  /// No description provided for @annualLeave.
  ///
  /// In en, this message translates to:
  /// **'Annual leave'**
  String get annualLeave;

  /// No description provided for @sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get sickLeave;

  /// No description provided for @unpaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Unpaid leave'**
  String get unpaidLeave;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get dayOff;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @entitled.
  ///
  /// In en, this message translates to:
  /// **'Entitled'**
  String get entitled;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @lastWorkingDay.
  ///
  /// In en, this message translates to:
  /// **'Last working day'**
  String get lastWorkingDay;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @longTerm.
  ///
  /// In en, this message translates to:
  /// **'Long-term loan'**
  String get longTerm;

  /// No description provided for @shiftChangeRequests.
  ///
  /// In en, this message translates to:
  /// **'Shift change requests'**
  String get shiftChangeRequests;

  /// No description provided for @proposedWorkDays.
  ///
  /// In en, this message translates to:
  /// **'Proposed work days'**
  String get proposedWorkDays;

  /// No description provided for @proposedStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get proposedStartTime;

  /// No description provided for @proposedEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get proposedEndTime;

  /// No description provided for @breakMinutes.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get breakMinutes;

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get effectiveFrom;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @kpis.
  ///
  /// In en, this message translates to:
  /// **'KPIs'**
  String get kpis;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @managerEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Manager evaluation'**
  String get managerEvaluation;

  /// No description provided for @turnoverRisk.
  ///
  /// In en, this message translates to:
  /// **'Turnover risk'**
  String get turnoverRisk;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @vacancy.
  ///
  /// In en, this message translates to:
  /// **'Vacancy'**
  String get vacancy;

  /// No description provided for @openings.
  ///
  /// In en, this message translates to:
  /// **'Openings'**
  String get openings;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @interview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interview;

  /// No description provided for @evaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated'**
  String get evaluated;

  /// No description provided for @hired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get hired;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @hire.
  ///
  /// In en, this message translates to:
  /// **'Hire'**
  String get hire;

  /// No description provided for @scheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at'**
  String get scheduledAt;

  /// No description provided for @interviewer.
  ///
  /// In en, this message translates to:
  /// **'Interviewer'**
  String get interviewer;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @onsite.
  ///
  /// In en, this message translates to:
  /// **'Onsite'**
  String get onsite;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoCall;

  /// No description provided for @phoneCall.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneCall;

  /// No description provided for @recommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get recommendation;

  /// No description provided for @hold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @criteria.
  ///
  /// In en, this message translates to:
  /// **'Criteria'**
  String get criteria;

  /// No description provided for @effectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective date'**
  String get effectiveDate;

  /// No description provided for @salaryHistory.
  ///
  /// In en, this message translates to:
  /// **'Salary history'**
  String get salaryHistory;

  /// No description provided for @isSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get isSubmitted;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @insuranceNo.
  ///
  /// In en, this message translates to:
  /// **'Insurance No.'**
  String get insuranceNo;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @self.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get self;

  /// No description provided for @supervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get supervisor;

  /// No description provided for @newLoan.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get newLoan;

  /// No description provided for @newLeave.
  ///
  /// In en, this message translates to:
  /// **'New leave'**
  String get newLeave;

  /// No description provided for @newResignation.
  ///
  /// In en, this message translates to:
  /// **'New resignation'**
  String get newResignation;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get selectBranch;

  /// No description provided for @selectSection.
  ///
  /// In en, this message translates to:
  /// **'Select section'**
  String get selectSection;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get titleAr;

  /// No description provided for @evaluate.
  ///
  /// In en, this message translates to:
  /// **'Evaluate'**
  String get evaluate;

  /// No description provided for @scheduleInterview.
  ///
  /// In en, this message translates to:
  /// **'Schedule interview'**
  String get scheduleInterview;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @checkInOut.
  ///
  /// In en, this message translates to:
  /// **'Check in / out'**
  String get checkInOut;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get loanAmount;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @loginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login Credentials'**
  String get loginCredentials;

  /// No description provided for @credentialsCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get credentialsCreated;

  /// No description provided for @credentialsInfo.
  ///
  /// In en, this message translates to:
  /// **'Username: {username}\nPassword: {password}'**
  String credentialsInfo(String username, String password);

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
