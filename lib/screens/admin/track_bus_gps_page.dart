import 'package:flutter/material.dart';

import '../../models/bus_gps.dart';
import '../../services/bus_gps_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class TrackBusGpsPage extends StatefulWidget {
  const TrackBusGpsPage({super.key});

  @override
  State<TrackBusGpsPage> createState() => _TrackBusGpsPageState();
}

class _TrackBusGpsPageState extends State<TrackBusGpsPage> {
  final _service = BusGpsService();
  final _searchController = TextEditingController();
  List<BusGps> _routes = const [];
  bool _includeInactive = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<BusGps> get _visibleRoutes {
    final query = _searchController.text.trim().toLowerCase();
    return _routes.where((route) {
      final active =
          route.isActive && route.busRouteStatus.toLowerCase() != 'inactive';
      if (!_includeInactive && !active) return false;
      if (query.isEmpty) return true;
      return [
        route.busRouteCode,
        route.busNo,
        route.busRouteDriver,
        route.busRouteStatus,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openForm([BusGps? route]) async {
    final saved = await showDialog<BusGps>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BusRouteForm(route: route),
    );
    if (saved == null) return;
    try {
      final result = await _service.save(saved);
      if (!mounted) return;
      setState(() {
        final index = _routes.indexWhere((item) => item.id == result.id);
        _routes = index == -1 ? [result, ..._routes] : [..._routes]
          ..[index] = result;
      });
      _message(
        route == null
            ? 'Bus route added successfully.'
            : 'Bus route updated successfully.',
      );
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _delete(BusGps route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus Route'),
        content: const Text('Are you sure you want to delete this Bus Route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || route.id == null) return;
    try {
      await _service.delete(route.id!);
      if (!mounted) return;
      setState(
        () => _routes = _routes.where((item) => item.id != route.id).toList(),
      );
      _message('Bus route deleted successfully.');
    } catch (error) {
      if (mounted) {
        _message(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = _visibleRoutes;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        title: const Text('Track Bus GPS'),
        actions: [
          IconButton(
            onPressed: _loadRoutes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 700 ? 16.0 : 32.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 32),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bus Routes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Include Inactive'),
                        selected: _includeInactive,
                        onSelected: (value) =>
                            setState(() => _includeInactive = value),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search Bus Routes',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _loadRoutes,
                        icon: const Icon(Icons.route),
                        label: const Text('Routes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    _StateMessage(
                      message: _error!,
                      icon: Icons.error_outline,
                      action: _loadRoutes,
                    )
                  else if (routes.isEmpty)
                    const _StateMessage(
                      message: 'No bus routes found.',
                      icon: Icons.directions_bus_outlined,
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 460,
                        mainAxisExtent: 270,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: routes.length,
                      itemBuilder: (context, index) => BusRouteCard(
                        route: routes[index],
                        onEdit: () => _openForm(routes[index]),
                        onDelete: () => _delete(routes[index]),
                        onMessage: () => _message(
                          'Message workflow selected for ${routes[index].busRouteCode}.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminDashboard,
              (route) => false,
            );
          }
          if (index == 3) {
            Navigator.of(context).pushNamed(AppRoutes.supportQuery);
          }
          if (index == 4) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
      ),
    );
  }
}

class BusRouteCard extends StatelessWidget {
  const BusRouteCard({
    super.key,
    required this.route,
    required this.onEdit,
    required this.onDelete,
    required this.onMessage,
  });

  final BusGps route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final online =
        route.hasGpsDevice.toLowerCase() == 'yes' &&
        route.gpsStatus.toLowerCase() == 'online';
    final active =
        route.isActive && route.busRouteStatus.toLowerCase() != 'inactive';
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.busRouteCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.gps_fixed,
                  color: online ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: online ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoLine(label: 'Bus No', value: route.busNo),
            _InfoLine(label: 'Driver', value: route.busRouteDriver),
            _InfoLine(
              label: 'Status',
              value: route.busRouteStatus,
              valueColor: active
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
            _InfoLine(
              label: 'Last Update',
              value: _formatDate(route.updatedAt),
            ),
            _InfoLine(label: 'Engine', value: route.engineStatus),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onMessage,
                  icon: const Icon(Icons.message_outlined),
                  tooltip: 'Message',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) => date == null
      ? 'Not available'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text('$label:')),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.icon, this.action});
  final String message;
  final IconData icon;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class BusRouteForm extends StatefulWidget {
  const BusRouteForm({super.key, this.route});
  final BusGps? route;

  @override
  State<BusRouteForm> createState() => _BusRouteFormState();
}

class _BusRouteFormState extends State<BusRouteForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late String _status;
  late String _hasGps;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _status = route?.busRouteStatus ?? 'Active';
    _hasGps = route?.hasGpsDevice ?? 'Yes';
    _controllers = {
      'code': TextEditingController(text: route?.busRouteCode ?? ''),
      'year': TextEditingController(text: route?.year ?? ''),
      'description': TextEditingController(
        text: route?.busRouteDescription ?? '',
      ),
      'driver': TextEditingController(text: route?.busRouteDriver ?? ''),
      'busNo': TextEditingController(text: route?.busNo ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    final old = widget.route;
    Navigator.pop(
      context,
      BusGps(
        id: old?.id,
        busRouteCode: _controllers['code']!.text.trim(),
        busRouteStatus: _status,
        year: _controllers['year']!.text.trim(),
        busRouteDescription: _controllers['description']!.text.trim(),
        busRouteDriver: _controllers['driver']!.text.trim(),
        busNo: _controllers['busNo']!.text.trim(),
        hasGpsDevice: _hasGps,
        gpsStatus: old?.gpsStatus ?? (_hasGps == 'Yes' ? 'Online' : 'Offline'),
        engineStatus: old?.engineStatus ?? 'OFF',
        isActive: _status == 'Active',
        createdAt: old?.createdAt,
        updatedAt: old?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.route != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(editing ? 'Edit Bus Routes' : 'Add Bus Routes')),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Bus Route Code', 'code'),
                _dropdown(
                  'Bus Route Status',
                  _status,
                  ['Active', 'Inactive'],
                  (value) => setState(() => _status = value!),
                ),
                _field('Year', 'year'),
                _field('Bus Route Description', 'description', maxLines: 3),
                _field('Bus Route Driver', 'driver'),
                _field('Bus No', 'busNo'),
                _dropdown(
                  'Bus has GPS Device',
                  _hasGps,
                  ['Yes', 'No'],
                  (value) => setState(() => _hasGps = value!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  for (final controller in _controllers.values) {
                    controller.clear();
                  }
                  setState(() {
                    _status = 'Active';
                    _hasGps = 'Yes';
                  });
                },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editing ? 'Update' : 'Insert'),
        ),
      ],
    );
  }

  Widget _field(String label, String key, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controllers[key],
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null || value.isEmpty ? '$label is required.' : null,
    ),
  );
}
