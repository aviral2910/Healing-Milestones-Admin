import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_palette.dart';
import '../../../users/data/users_repository.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';

final allUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(usersRepositoryProvider).getUsers();
});

class ManageAdminsScreen extends ConsumerStatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  ConsumerState<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends ConsumerState<ManageAdminsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isUpdating = false;

  Future<void> _updateRole(UserModel user, String newRole) async {
    setState(() => _isUpdating = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.dio.patch(
        '/api/admin/users/${user.userId}/role',
        queryParameters: {'role': newRole},
      );
      // ignore: unused_result
      ref.refresh(allUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated role for ${user.email}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.getThemeData(ThemePalette.goldenDark);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Admins'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (users) {
                final filtered = users.where((u) {
                  final emailMatch = u.email.toLowerCase().contains(_searchQuery);
                  final nameMatch = u.displayName.toLowerCase().contains(_searchQuery);
                  return emailMatch || nameMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No users found', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isAdmin = user.role == UserRole.organization;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: user.profilePicture == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        user.displayName.isEmpty ? 'No Name' : user.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${user.email}\nRole: ${user.role.name}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdmin ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          foregroundColor: isAdmin ? Colors.red : Colors.green,
                        ),
                        onPressed: _isUpdating
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(isAdmin ? 'Revoke Admin' : 'Grant Admin'),
                                    content: Text(
                                      isAdmin 
                                          ? 'Are you sure you want to revoke admin access from ${user.email}?'
                                          : 'Are you sure you want to make ${user.email} an admin? They will have full access to this portal.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _updateRole(user, isAdmin ? 'member' : 'organization');
                                        },
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        child: Text(isAdmin ? 'Revoke' : 'Make Admin'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
