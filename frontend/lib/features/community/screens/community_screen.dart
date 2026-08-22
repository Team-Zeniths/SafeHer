import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../routes/route_names.dart';
import '../providers/community_provider.dart';
import '../../../models/community_post_model.dart';

/// Community feed screen — displays community posts and incident reports.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'Report Incident',
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.sosRed),
            onPressed: () => context.push(RouteNames.incidentReport),
          ),
          IconButton(
            tooltip: 'Create Post',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCreatePostSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionOptions(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Share & Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 6),
              children: [
                _FilterChip(label: 'All', selected: cp.activeFilter == null, onTap: () => cp.setFilter(null)),
                const SizedBox(width: AppSizes.sm),
                ...PostCategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: _FilterChip(
                        label: cat.label,
                        selected: cp.activeFilter == cat,
                        onTap: () => cp.setFilter(cat),
                        color: _categoryColor(cat),
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          // Feed
          Expanded(
            child: cp.status == CommunityStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : cp.status == CommunityStatus.error
                    ? ErrorStateWidget(message: cp.errorMessage ?? 'Failed to load posts', onRetry: cp.loadPosts)
                    : cp.posts.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.people_outline,
                            title: 'No posts yet',
                            subtitle: 'Be the first to share a safety tip or report an incident!',
                            iconColor: AppColors.primary,
                          )
                        : RefreshIndicator(
                            onRefresh: cp.loadPosts,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 80),
                              itemCount: cp.posts.length,
                              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.md),
                              itemBuilder: (context, i) => _PostCard(post: cp.posts[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(PostCategory cat) {
    switch (cat) {
      case PostCategory.alert:
        return AppColors.sosRed;
      case PostCategory.tip:
        return AppColors.info;
      case PostCategory.safety:
        return AppColors.success;
      case PostCategory.question:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  void _showActionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightOutline,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sosRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.report_problem_rounded, color: AppColors.sosRed),
                ),
                title: const Text('Report Incident', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('File a detailed safety alert with location coordinates'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(RouteNames.incidentReport);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                ),
                title: const Text('Create Community Post', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Share a tip, ask a question, or post a safety update'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreatePostSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (_) => const _CreatePostSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: selected ? c : AppColors.lightOutline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textMutedLight,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final CommunityPostModel post;

  @override
  Widget build(BuildContext context) {
    final cp = context.read<CommunityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: post.isAlert
              ? AppColors.sosRed.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
          width: post.isAlert ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                AvatarWidget(name: post.authorName, radius: 18),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(_timeAgo(post.createdAt), style: TextStyle(color: AppColors.textMutedLight, fontSize: 11)),
                    ],
                  ),
                ),
                _CategoryBadge(post.category),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            // Content
            Text(post.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
            if (post.location != null && post.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      post.location!,
                      style: const TextStyle(color: AppColors.textMutedLight, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.xs),
            // Actions
            Row(
              children: [
                _ActionButton(
                  icon: post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likeCount}',
                  color: post.isLikedByMe ? AppColors.sosRed : AppColors.textMutedLight,
                  onTap: () => cp.toggleLike(post.id),
                ),
                const SizedBox(width: AppSizes.md),
                _ActionButton(
                  icon: Icons.comment_outlined,
                  label: '${post.commentCount}',
                  color: AppColors.textMutedLight,
                  onTap: () {},
                ),
                const Spacer(),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.textMutedLight,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Safety alert link copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.category);
  final PostCategory category;

  Color _color() {
    switch (category) {
      case PostCategory.alert:
        return AppColors.sosRed;
      case PostCategory.tip:
        return AppColors.info;
      case PostCategory.safety:
        return AppColors.success;
      case PostCategory.question:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
      child: Text(category.label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Create Post Sheet ─────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  PostCategory _category = PostCategory.safety;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final success = await context.read<CommunityProvider>().createPost(
          content: _contentCtrl.text.trim(),
          category: _category,
          location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
          isAnonymous: _isAnonymous,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published to Community! 📣')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lightOutline, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Community Post', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.md),
                  // Category selection
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.xs,
                    children: PostCategory.values.map((cat) {
                      final sel = cat == _category;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: sel,
                        onSelected: (_) => setState(() => _category = cat),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: sel ? AppColors.primary : null, fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: _locationCtrl,
                    decoration: InputDecoration(
                      hintText: 'Location / Area (optional)',
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share a safety tip, alert, or update...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SwitchListTile.adaptive(
                    value: _isAnonymous,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                    title: const Text('Post anonymously'),
                    subtitle: const Text('Your identity will remain private'),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.primary,
                  ),
                  const SizedBox(height: AppSizes.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
                      label: Text(_isLoading ? 'Publishing...' : 'Publish Post'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

