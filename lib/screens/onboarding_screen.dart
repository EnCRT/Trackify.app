import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/user.dart';
import '../providers/vehicle_provider.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // User Data
  String _nickname = '';
  String _firstName = '';
  String _lastName = '';

  // Vehicle Data
  String _brand = '';
  String _model = '';
  String _year = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.two_wheeler, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.welcome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.setupPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yourProfile,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.nickname,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.required
                          : null,
                      onSaved: (value) => _nickname = value!,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.firstName,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? AppLocalizations.of(context)!.required
                                : null,
                            onSaved: (value) => _firstName = value!,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.lastName,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? AppLocalizations.of(context)!.required
                                : null,
                            onSaved: (value) => _lastName = value!,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context)!.firstVehicle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.brandHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.branding_watermark),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.required
                          : null,
                      onSaved: (value) => _brand = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.modelHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.motorcycle),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.required
                          : null,
                      onSaved: (value) => _model = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.year,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return AppLocalizations.of(context)!.required;
                        if (int.tryParse(value) == null)
                          return AppLocalizations.of(context)!.mustBeNumber;
                        return null;
                      },
                      onSaved: (value) => _year = value!,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();

                            final newUser = User(
                              nickname: _nickname,
                              firstName: _firstName,
                              lastName: _lastName,
                              joinDate: DateTime.now(),
                            );
                            await context.read<UserProvider>().saveUser(
                              newUser,
                            );

                            final newVehicle = Vehicle(
                              brand: _brand,
                              model: _model,
                              year: int.parse(_year),
                            );
                            await context.read<VehicleProvider>().addVehicle(
                              newVehicle,
                            );
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.saveAndContinue,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
