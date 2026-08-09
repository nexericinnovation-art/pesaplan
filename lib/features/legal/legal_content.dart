// Draft Terms of Service and Privacy Policy for PesaPlan.
//
// IMPORTANT: This is a starting draft, not reviewed by a lawyer. PesaPlan
// handles real financial data and operates primarily in Kenya, which has
// its own Data Protection Act (2019) with specific obligations (registered
// data controller/processor status, data subject rights, cross-border
// transfer rules). Have this reviewed by a lawyer familiar with Kenyan data
// protection and consumer law before treating it as final. Every [BRACKETED]
// placeholder needs a real value before this ships.

class LegalContent {
  static const String lastUpdated = '9 August 2026';

  static const String termsOfService = '''
1. ACCEPTANCE OF TERMS

By creating an account or using PesaPlan ("the App", "the Service"), you agree to these Terms of Service. If you do not agree, do not use the App. These terms are between you and PesaPan, a company registered in Kenya ("PesaPlan", "we", "us").

2. WHAT PESAPLAN IS — AND ISN'T

PesaPlan is a personal finance tracking and planning tool. You manually record your own income, expenses, budgets, savings goals, and debts, and the App calculates summaries, a Financial Health Score, and insights from the data you provide.

PesaPlan is NOT a bank, lender, payment service provider, or licensed financial institution. We do not hold, move, or have access to your money, bank accounts, or mobile money accounts. We do not initiate transactions on your behalf. Any figures you enter are self-reported by you and are only as accurate as what you enter.

3. NOT FINANCIAL ADVICE

The Financial Health Score, budget warnings, debt payoff comparisons (Snowball/Avalanche), and any other insights the App generates are general, educational information calculated from your own data. They are not personalized financial, investment, tax, or legal advice, and should not be treated as a recommendation. Consider your own circumstances, or consult a qualified professional, before making financial decisions.

4. ELIGIBILITY AND ACCOUNTS

You must be at least 18 years old to use PesaPlan. You are responsible for keeping your login credentials secure and for all activity under your account. Tell us immediately if you believe your account has been compromised.

5. ACCEPTABLE USE

You agree not to: use the App for any unlawful purpose; attempt to gain unauthorized access to other users' data or to our systems; reverse-engineer, decompile, or scrape the App; or use the App to store or transmit false financial information intended to deceive a third party (e.g., for loan fraud).

6. YOUR DATA

You own the financial data you enter. Our Privacy Policy explains what we collect, how we use it, and your rights over it. By using the App, you also agree to the Privacy Policy.

7. SERVICE AVAILABILITY

We aim to keep PesaPlan available and your data accurate, but we don't guarantee uninterrupted access, and we're not liable for losses caused by outages, bugs, or data unavailability, except where liability cannot be excluded under Kenyan law.

8. LIMITATION OF LIABILITY

To the maximum extent permitted by law, PesaPlan and its operators are not liable for indirect, incidental, or consequential damages arising from your use of the App, including financial decisions made based on information in the App. Nothing in these terms limits liability for fraud or for anything that cannot legally be excluded.

9. TERMINATION

You may stop using the App and delete your account at any time. We may suspend or terminate accounts that violate these terms.

10. CHANGES TO THESE TERMS

We may update these terms from time to time. Continued use of the App after an update means you accept the revised terms. Material changes will be flagged in the App.

11. GOVERNING LAW

These terms are governed by the laws of Kenya. Disputes will be subject to the exclusive jurisdiction of the courts of Kenya.

12. CONTACT

Questions about these terms: nexericinnovation.com
''';

  static const String privacyPolicy = '''
1. WHO WE ARE

PesaPlan is operated by PesaPlan ("we", "us"), registered in Kenya. We are the data controller for the personal data described below, in the sense used by Kenya's Data Protection Act, 2019.

2. WHAT WE COLLECT

Account information: your name, email address, and authentication details, handled by our authentication provider, Clerk (see Section 4).

Financial data you enter: transactions, categories, budgets, savings goals, debts, and recurring payments — all manually entered by you. We do not collect this data from any bank, mobile money provider, or third party; you type it in.

Usage data: basic technical information (device type, app version, crash logs) used to keep the App working.

3. HOW WE USE YOUR DATA

To provide the App's features: your dashboard, transaction history, budget tracking, Financial Health Score, insights, and exported reports are all calculated directly from the data you enter.

To secure your account and enforce access control, so only you can see your own financial data.

We do not sell your personal data, and we do not share your financial data with third parties for their own marketing purposes.

4. THIRD-PARTY PROCESSORS

We use the following service providers to operate PesaPlan, each of whom processes data on our behalf under their own security and privacy commitments:

• Clerk — handles authentication (sign-in, sign-up, password reset). Clerk processes your email address and authentication credentials.
• Supabase — hosts our database. Your financial data (transactions, budgets, goals, debts) is stored here, protected by row-level security so only your authenticated account can read or write your own records.

We do not send your financial data to any AI or analytics service outside of what's needed to run the App's own features.

5. DATA SECURITY

Your financial data is protected by database-level access rules (row-level security) that restrict every read and write to your own account. Data is encrypted in transit. No security measure is perfect, and we can't guarantee absolute security, but unauthorized access to another user's data is something the system is specifically designed to prevent.

6. YOUR RIGHTS

Under Kenya's Data Protection Act, and as a matter of how we've built the App, you have the right to:

• Access the personal data we hold about you — most of it is visible directly in the App.
• Correct inaccurate data — you can edit or delete transactions, budgets, goals, and debts directly.
• Delete your account and associated data — contact us at [SUPPORT EMAIL] to request full account deletion.
• Object to or restrict certain processing, where applicable.

7. DATA RETENTION

We retain your data for as long as your account is active. If you delete your account, we delete your financial data within [RETENTION PERIOD, e.g. 30 days], except where we're required to retain records for a longer period by law.

8. CHILDREN'S PRIVACY

PesaPlan is not intended for anyone under 18. We don't knowingly collect data from children.

9. CHANGES TO THIS POLICY

We may update this policy as the App changes. Material changes will be flagged in the App.

10. CONTACT

Questions about this policy, or to exercise your data rights: nexericinnovation@gmail.com
''';
}
