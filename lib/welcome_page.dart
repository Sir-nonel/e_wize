import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'styled_page_scaffold.dart';
import 'booking_detail_page.dart';

class WelcomePage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const WelcomePage({super.key, required this.username, required this.onLogout});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String _sortOption = 'A-Z';
  RangeValues _priceRange = const RangeValues(0, 5000);

  final Map<String, IconData> hallIcons = {
    'Seminar Room': Icons.meeting_room,
    'Community Hall': Icons.groups,
    'Studio Space': Icons.music_video,
    'Rooftop Venue': Icons.terrain,
    'Ballroom': Icons.cake,
  };

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> halls) {
    final filtered = halls.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num).toDouble();
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      if (_sortOption == 'A-Z') {
        return (dataA['title'] ?? '').compareTo(dataB['title'] ?? '');
      } else if (_sortOption == 'Low-High') {
        return (dataA['price'] as num).compareTo(dataB['price'] as num);
      } else {
        return (dataB['price'] as num).compareTo(dataA['price'] as num);
      }
    });

    return filtered;
  }

  Widget _priceBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String tempSort = _sortOption;
    RangeValues tempRange = _priceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                // Sort section
                const Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                RadioGroup<String>(
                  groupValue: tempSort,
                  onChanged: (val) => setSheetState(() => tempSort = val!),
                  child: Column(
                    children: [
                      for (final e in <String, String>{
                        'A-Z': 'Alphabetical A-Z',
                        'Low-High': 'Price: Low to High',
                        'High-Low': 'Price: High to Low',
                      }.entries)
                        RadioListTile<String>(
                          value: e.key,
                          title: Text(e.value),
                          activeColor: Colors.lightBlue,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const Divider(),

                // Price range section
                const Text(
                  'Price Range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${tempRange.start.toStringAsFixed(0)} — RM ${tempRange.end.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                RangeSlider(
                  values: tempRange,
                  min: 0,
                  max: 5000,
                  divisions: 100,
                  activeColor: Colors.lightBlue,
                  inactiveColor: Colors.lightBlue.shade100,
                  onChanged: (values) =>
                      setSheetState(() => tempRange = values),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _priceBox(
                        'Min price',
                        'RM ${tempRange.start.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _priceBox(
                        'Max price',
                        'RM ${tempRange.end.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOption = tempSort;
                        _priceRange = tempRange;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyledPageScaffold(
      title: 'EventWize',
      actions: [
        if (widget.username.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Update Profile',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'username': widget.username},
              );
            },
          ),
        IconButton(
          icon: Icon(
            widget.username.isEmpty ? Icons.login : Icons.logout,
            color: Colors.white,
          ),
          tooltip: widget.username.isEmpty ? 'Login' : 'Logout',
          onPressed: () {
            if (widget.username.isEmpty) {
              Navigator.pushNamed(context, '/login');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
              final nav = Navigator.of(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  widget.onLogout();
                  nav.pushReplacementNamed('/login');
                }
              });
            }
          },
        ),
      ],
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Halls').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allHalls = snapshot.data!.docs;
              final halls = _applyFilters(allHalls);

              if (halls.isEmpty) {
                return Center(
                  child: Text(
                    'No halls match your filters.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
                ),
                itemCount: halls.length,
                itemBuilder: (context, index) {
                  final hall = halls[index].data() as Map<String, dynamic>;
                  final title = hall['title'] ?? '';
                  final price = (hall['price'] as num).toDouble();

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.lightBlue.shade50,
                    child: ListTile(
                      leading: Icon(
                        hallIcons[title] ?? Icons.event,
                        color: Colors.lightBlue,
                        size: 32,
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('RM ${price.toStringAsFixed(2)}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsPage(
                              username: widget.username,
                              hallData: hall,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          // Filter FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 8),
              child: FloatingActionButton(
                backgroundColor: Colors.lightBlue,
                tooltip: 'Filter & Sort',
                onPressed: _showFilterSheet,
                child: const Icon(Icons.tune, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
