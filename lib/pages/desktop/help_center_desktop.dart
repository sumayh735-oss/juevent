import 'package:flutter/material.dart';

class HelpCenterDesktop extends StatefulWidget {
  const HelpCenterDesktop({super.key});

  @override
  State<HelpCenterDesktop> createState() => _HelpCenterDesktopState();
}

class _HelpCenterDesktopState extends State<HelpCenterDesktop> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_Faq> _faqs = const [
    _Faq('How do I create an event?',
        'Go to Events → New Event, then fill in title, date, venue, and click Save.'),
    _Faq('How do I edit my profile?',
        'Open your profile page and tap Edit to change your details.'),
    _Faq('Why was my event rejected?',
        'An admin reviews all events. If rejected, check the email for the reason and resubmit.'),
    _Faq('Can I cancel an approved event?',
        'Yes. Contact support or ask an admin to revert it to Pending.'),
    _Faq('Where can I see today’s events?',
        'Open Dashboard → Today, or use the Today tab in Admin.'),
    _Faq('How do I reset my password?',
        'Use the “Forgot password” option on the login page to receive a reset email.'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _faqs
        : _faqs.where((f) =>
            f.q.toLowerCase().contains(_query) ||
            f.a.toLowerCase().contains(_query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        elevation: 0.8,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade600, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Find quick answers and guides',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      // optional: go to Support page
                    },
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Contact Support'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search articles or questions…',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () => _searchCtrl.clear(),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            // Quick topics
            Text('Top Topics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TopicCard(
                  icon: Icons.event,
                  title: 'Events',
                  desc: 'Creating & managing events',
                  onTap: () {},
                ),
                _TopicCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Account',
                  desc: 'Profile, password & privacy',
                  onTap: () {},
                ),
                _TopicCard(
                  icon: Icons.dashboard_customize,
                  title: 'Admin',
                  desc: 'Approvals, statuses & rules',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 22),
            Text('FAQs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            // FAQs
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No results for “$_query”. Try another keyword.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...filtered.map((f) => _FaqTile(faq: f)),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  const _TopicCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.withOpacity(.12),
                child: Icon(icon, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.2),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (v) => setState(() => open = v),
        leading: Icon(
          open ? Icons.help : Icons.help_outline,
          color: Colors.indigo,
        ),
        title: Text(
          widget.faq.q,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(widget.faq.a, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}
