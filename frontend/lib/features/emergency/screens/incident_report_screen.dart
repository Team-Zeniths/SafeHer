import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/api_service.dart';
import '../../community/providers/community_provider.dart';

/// Incident report screen — lets user file a safety report.
class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'Harassment';
  bool _isLoading = false;
  bool _isAnonymous = false;

  final _types = ['Harassment', 'Stalking', 'Theft', 'Unsafe Area', 'Other'];

  /// Maps the form's display labels to the backend's IncidentReport.Category
  /// values (apps.community.models.IncidentReport).
  static const _categoryMap = {
    'Harassment': 'harassment',
    'Stalking': 'stalking',
    'Theft': 'theft',
    'Unsafe Area': 'unsafe_area',
    'Other': 'other',
  };

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 4),
              ),
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (locErr) {
        debugPrint('Location lookup failed for incident report: $locErr');
      }

      final locationText = _locationCtrl.text.trim();
      final descriptionText = _descCtrl.text.trim();
      final formattedDesc = locationText.isNotEmpty
          ? 'Location: $locationText\n\n$descriptionText'
          : descriptionText;

      await ApiService.instance.post('community/reports/', data: {
        'category': _categoryMap[_selectedType] ?? 'other',
        'description': formattedDesc,
        'location_lat': lat,
        'location_lng': lng,
        'is_anonymous': _isAnonymous,
      });

      // Refresh community feed provider so newly created incident report is visible immediately
      if (mounted) {
        context.read<CommunityProvider>().loadPosts();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you for keeping the community safe! 💪')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help keep your community safe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
                ),
                const SizedBox(height: AppSizes.xl),
                Text('Incident Type', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  children: _types.map((t) {
                    final selected = t == _selectedType;
                    return FilterChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedType = t),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : null,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),
                CustomTextField(
                  label: 'Location',
                  hint: 'Enter the incident location',
                  controller: _locationCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a location' : null,
                ),
                const SizedBox(height: AppSizes.md),
                CustomTextField(
                  label: 'Description',
                  hint: 'Describe what happened...',
                  controller: _descCtrl,
                  maxLines: 5,
                  validator: (v) => v == null || v.length < 10 ? 'Please provide more details' : null,
                ),
                const SizedBox(height: AppSizes.md),
                SwitchListTile.adaptive(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  title: const Text('Submit anonymously'),
                  subtitle: const Text('Your identity will be kept private'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                ),
                const SizedBox(height: AppSizes.xl),
                GradientButton(
                  label: 'Submit Report',
                  icon: Icons.send_rounded,
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
