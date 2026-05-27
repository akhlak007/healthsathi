import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<Map<String, String>> _clinicians = [
    {
      'name': 'Dr. Yasmin Begum',
      'specialty': 'Gynaecology & Cardiology Expert',
      'location': 'Dhanmondi, Dhaka',
      'availability': 'Sat - Wed (5 PM - 9 PM)',
    },
    {
      'name': 'Professor Dr. Arifur Rahman',
      'specialty': 'Interventional Cardiologist',
      'location': 'Mirpur, Dhaka',
      'availability': 'Everyday (10 AM - 1 PM)',
    },
    {
      'name': 'Dr. Nargis Sultana',
      'specialty': 'Emergency Medicine Specialist',
      'location': 'Uttara, Dhaka',
      'availability': 'Mon - Thu (2 PM - 6 PM)',
    },
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final filteredClinicians = _clinicians.where((c) {
      final name = c['name']!.toLowerCase();
      final spec = c['specialty']!.toLowerCase();
      final loc = c['location']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || spec.contains(query) || loc.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Clinicians & Centers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Styled Search Text Field mimicking Figma input boxes
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search doctors, specialties, or clinics...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Specialists in Dhaka',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredClinicians.length} ACTIVE',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.primary, fontFamily: 'JetBrains Mono'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: filteredClinicians.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.outlineVariant.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text('No active doctors or clinics found', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Refine your search tokens and retry.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredClinicians.length,
                itemBuilder: (context, index) {
                  final doc = filteredClinicians[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: Colors.grey.shade100, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.08),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(doc['specialty']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11.5)),
                                const Divider(height: 16, thickness: 0.5),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.outline),
                                    const SizedBox(width: 4),
                                    Text(doc['location']!, style: const TextStyle(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text(doc['availability']!, style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Appointment requested with ${doc['name']}'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 3),
    );
  }
}
