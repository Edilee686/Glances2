import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _s;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _s = Session.instance.me?.settings ?? Settings();
  }

  Future<void> _save(Settings next) async {
    setState(() { _s = next; _saving = true; });
    try {
      await Api.instance.saveSettings(next);
      await Session.instance.refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Session.instance.me;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CirclePhoto(
                  url: me?.images.isNotEmpty == true
                      ? me!.images.first.url
                      : null,
                  size: 64,
                  fallbackLabel: me?.name,
                  ringWidth: 2,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me?.name ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(me?.email ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: GlancesColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          SwitchListTile(
            title: const Text('Invisibility'),
            subtitle: const Text('Browse without appearing to anyone'),
            value: _s.invisibility,
            onChanged: (v) => _save(_s.copyWith(invisibility: v)),
          ),
          SwitchListTile(
            title: const Text('Show profile information'),
            value: _s.showInfo,
            onChanged: (v) => _save(_s.copyWith(showInfo: v)),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _s.notification,
            onChanged: (v) => _save(_s.copyWith(notification: v)),
          ),
          SwitchListTile(
            title: const Text('Only show people who are online'),
            value: _s.online,
            onChanged: (v) => _save(_s.copyWith(online: v)),
          ),

          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text('Interested in',
                style: TextStyle(color: GlancesColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'woman', label: Text('Women')),
                ButtonSegment(value: 'man', label: Text('Men')),
                ButtonSegment(value: 'both', label: Text('Both')),
              ],
              selected: {_s.meetGender},
              onSelectionChanged: (v) =>
                  _save(_s.copyWith(meetGender: v.first)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text('Age  ${_s.preferredAgeFrom} – ${_s.preferredAgeTo}',
                style: const TextStyle(color: GlancesColors.textSecondary)),
          ),
          RangeSlider(
            values: RangeValues(
                _s.preferredAgeFrom.toDouble(), _s.preferredAgeTo.toDouble()),
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: GlancesColors.primary,
            labels: RangeLabels('${_s.preferredAgeFrom}', '${_s.preferredAgeTo}'),
            onChanged: (v) => setState(() => _s = _s.copyWith(
                preferredAgeFrom: v.start.round(),
                preferredAgeTo: v.end.round())),
            onChangeEnd: (v) => _save(_s.copyWith(
                preferredAgeFrom: v.start.round(),
                preferredAgeTo: v.end.round())),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Distance  ${_s.distance} m',
                style: const TextStyle(color: GlancesColors.textSecondary)),
          ),
          Slider(
            value: _s.distance.clamp(10, 500).toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: GlancesColors.primary,
            label: '${_s.distance} m',
            onChanged: (v) =>
                setState(() => _s = _s.copyWith(distance: v.round())),
            onChangeEnd: (v) => _save(_s.copyWith(distance: v.round())),
          ),

          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Update my location now'),
            subtitle: Text(Session.instance.locationStatus ?? 'Working'),
            onTap: () async {
              final ok = await Session.instance.pushLocationNow();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Location sent' : 'Could not get location'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await Session.instance.signOut();
              if (mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Delete account',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete your account?'),
                  content: const Text(
                      'This removes your profile, photos, likes, matches and '
                      'messages. It cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await Api.instance.deleteAccount();
                  await Session.instance.signOut();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) showError(context, e);
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
