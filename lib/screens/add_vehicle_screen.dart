import 'package:flutter/material.dart';
import 'package:moto_lap_timer/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  String _brand = '';
  String _model = '';
  String _year = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.addVehicle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.motorcycle,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 32),
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
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.required;
                    }
                    if (int.tryParse(value) == null) {
                      return AppLocalizations.of(context)!.mustBeNumber;
                    }
                    return null;
                  },
                  onSaved: (value) => _year = value!,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        final newVehicle = Vehicle(
                          brand: _brand,
                          model: _model,
                          year: int.parse(_year),
                        );
                        await context.read<VehicleProvider>().addVehicle(
                          newVehicle,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
