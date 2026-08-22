import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/gradient_button.dart';
import '../providers/contacts_provider.dart';
import '../../../models/contact_model.dart';

/// Trusted contacts list screen.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showAddContactSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.sm, AppSizes.lg, AppSizes.sm),
            child: TextField(
              onChanged: cp.search,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
            ),
          ),
          // List
          Expanded(
            child: cp.status == ContactsStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : cp.contacts.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.group_outlined,
                        title: 'No contacts yet',
                        subtitle: 'Add trusted contacts who will be notified during emergencies.',
                        actionLabel: 'Add Contact',
                        onAction: () => _showAddContactSheet(context),
                        iconColor: AppColors.primary,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.sm),
                        itemCount: cp.contacts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                        itemBuilder: (context, i) => _ContactCard(
                          contact: cp.contacts[i],
                          onEdit: () => _showEditSheet(context, cp.contacts[i]),
                          onDelete: () => _confirmDelete(context, cp.contacts[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddContactSheet(BuildContext context) {
    _ContactFormSheet.show(context, contact: null);
  }

  void _showEditSheet(BuildContext context, ContactModel contact) {
    _ContactFormSheet.show(context, contact: contact);
  }

  Future<void> _confirmDelete(BuildContext context, ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text('Remove ${contact.name} from your trusted contacts?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Remove', style: TextStyle(color: AppColors.sosRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ContactsProvider>().deleteContact(contact.id);
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onEdit, required this.onDelete});
  final ContactModel contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: contact.isPrimary ? AppColors.primary.withValues(alpha: 0.4) : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: contact.isPrimary ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
        leading: AvatarWidget(name: contact.name, radius: 24),
        title: Row(
          children: [
            Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (contact.isPrimary) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: const Text('Primary', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone),
            if (contact.relationship != null)
              Text(contact.relationship!, style: TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
          ],
        ),
        isThreeLine: contact.relationship != null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: AppColors.sosRed))),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit Contact Bottom Sheet ──────────────────────────────────────────

class _ContactFormSheet extends StatefulWidget {
  const _ContactFormSheet({this.contact});
  final ContactModel? contact;

  static void show(BuildContext context, {ContactModel? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => _ContactFormSheet(contact: contact),
    );
  }

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relCtrl;
  bool _isPrimary = false;
  bool _notifySOS = true;
  bool _notifyJourney = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.contact?.name);
    _phoneCtrl = TextEditingController(text: widget.contact?.phone);
    _relCtrl = TextEditingController(text: widget.contact?.relationship);
    _isPrimary = widget.contact?.isPrimary ?? false;
    _notifySOS = widget.contact?.isNotifyOnSOS ?? true;
    _notifyJourney = widget.contact?.isNotifyOnJourney ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final cp = context.read<ContactsProvider>();
    final contact = ContactModel(
      id: widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      relationship: _relCtrl.text.trim().isEmpty ? null : _relCtrl.text.trim(),
      isPrimary: _isPrimary,
      isNotifyOnSOS: _notifySOS,
      isNotifyOnJourney: _notifyJourney,
    );
    if (widget.contact == null) {
      await cp.addContact(contact);
    } else {
      await cp.updateContact(contact);
    }
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.contact == null ? 'Add Contact' : 'Edit Contact',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.lg),
                  CustomTextField(label: 'Name', hint: 'Full name', controller: _nameCtrl, prefixIcon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                  const SizedBox(height: AppSizes.md),
                  CustomTextField(label: 'Phone Number', hint: '+91 XXXXX XXXXX', controller: _phoneCtrl,
                      keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined,
                      validator: (v) => v == null || v.length < 8 ? 'Enter a valid number' : null),
                  const SizedBox(height: AppSizes.md),
                  CustomTextField(label: 'Relationship (optional)', hint: 'e.g. Sister, Friend', controller: _relCtrl, prefixIcon: Icons.favorite_outline),
                  const SizedBox(height: AppSizes.md),
                  SwitchListTile.adaptive(value: _isPrimary, onChanged: (v) => setState(() => _isPrimary = v),
                      title: const Text('Set as primary contact'), contentPadding: EdgeInsets.zero, activeTrackColor: AppColors.primary),
                  SwitchListTile.adaptive(value: _notifySOS, onChanged: (v) => setState(() => _notifySOS = v),
                      title: const Text('Notify on SOS'), contentPadding: EdgeInsets.zero, activeTrackColor: AppColors.sosRed),
                  SwitchListTile.adaptive(value: _notifyJourney, onChanged: (v) => setState(() => _notifyJourney = v),
                      title: const Text('Notify on Journey'), contentPadding: EdgeInsets.zero, activeTrackColor: AppColors.info),
                  const SizedBox(height: AppSizes.lg),
                  GradientButton(label: widget.contact == null ? 'Add Contact' : 'Save Changes',
                      icon: Icons.check_rounded, onPressed: _save, isLoading: _isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
