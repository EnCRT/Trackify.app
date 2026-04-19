import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/user_provider.dart';
import 'add_vehicle_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();

    final user = userProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.profile,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // User Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? AppLocalizations.of(context)!.unknownUser,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '@${user?.nickname ?? 'nickname'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _getMemberSince(user?.joinDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.memberSince,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Garage Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.garage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.deepPurpleAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVehicleScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (vehicleProvider.vehicles.isEmpty)
            Center(
              child: Text(
                AppLocalizations.of(context)!.noVehicle,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vehicleProvider.vehicles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final v = vehicleProvider.vehicles[index];
                final bool isFav = v.isFavorite == true;

                return GestureDetector(
                  onTap: () {
                    vehicleProvider.setFavorite(v);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.deepPurpleAccent.withOpacity(0.12)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFav
                            ? Colors.deepPurpleAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.8),
                        width: isFav ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isFav
                              ? Colors.deepPurpleAccent.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isFav
                                ? Colors.deepPurpleAccent.withOpacity(0.2)
                                : Colors.deepPurpleAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.star : Icons.two_wheeler,
                            color: Colors.deepPurpleAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.brand,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${v.year} ${v.model}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isFav
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isFav)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.deepPurpleAccent,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 280), // padding for bottom nav
        ],
      ),
    );
  }

  String _getMemberSince(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
