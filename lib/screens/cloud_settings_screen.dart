import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/hybrid_database_provider.dart';

class CloudSettingsScreen extends StatefulWidget {
  const CloudSettingsScreen({super.key});

  @override
  State<CloudSettingsScreen> createState() => _CloudSettingsScreenState();
}

class _CloudSettingsScreenState extends State<CloudSettingsScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cloud Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Storage Options',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose where your data is stored and synchronized',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            Consumer<HybridDatabaseProvider>(
              builder: (context, hybridProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          'Local Storage Only',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Data stored only on this device',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Radio<bool>(
                          value: false,
                          groupValue: hybridProvider.isUsingCloud,
                          onChanged: (value) {
                            if (value != null) {
                              hybridProvider.toggleStorageMode(value);
                            }
                          },
                        ),
                        onTap: () {
                          hybridProvider.toggleStorageMode(false);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Cloud Storage',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Data synchronized with cloud (requires account)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Radio<bool>(
                          value: true,
                          groupValue: hybridProvider.isUsingCloud,
                          onChanged: (value) {
                            if (value != null) {
                              hybridProvider.toggleStorageMode(value);
                            }
                          },
                        ),
                        onTap: () {
                          hybridProvider.toggleStorageMode(true);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              'Synchronization',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sync your data between local storage and cloud',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Sync Local to Cloud',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Upload all local data to cloud storage',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: _isSyncing
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.cloud_upload),
                            onPressed: _syncLocalToCloud,
                          ),
                    onTap: _syncLocalToCloud,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'Sync Cloud to Local',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Download all cloud data to local storage',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: _isSyncing
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.cloud_download),
                            onPressed: _syncCloudToLocal,
                          ),
                    onTap: _syncCloudToLocal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Important Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Cloud storage requires a free Firebase account\n'
                    '• Data is automatically synchronized when using cloud mode\n'
                    '• Local data remains on your device even when using cloud mode\n'
                    '• Sync operations may take a few moments depending on data size',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
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

  Future<void> _syncLocalToCloud() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final hybridProvider = Provider.of<HybridDatabaseProvider>(
        context,
        listen: false,
      );
      
      await hybridProvider.syncLocalToCloud();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized to cloud successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error synchronizing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _syncCloudToLocal() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final hybridProvider = Provider.of<HybridDatabaseProvider>(
        context,
        listen: false,
      );
      
      await hybridProvider.syncCloudToLocal();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized to local storage successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error synchronizing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}