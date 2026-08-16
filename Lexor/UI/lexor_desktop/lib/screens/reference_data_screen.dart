import 'package:flutter/material.dart';
import 'package:lexor_desktop/models/reference_models.dart';
import 'package:lexor_desktop/providers/reference_providers.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/reference_tab.dart';

/// "Reference data" screen — CRUD cards for all lookup tables.
class ReferenceDataScreen extends StatefulWidget {
  const ReferenceDataScreen({super.key});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen>
    with SingleTickerProviderStateMixin {
  static const _tabLabels = [
    'Gradovi',
    'Države',
    'Odjeli',
    'Pozicije',
    'Tipovi ugovora',
    'Tipovi odsustva',
    'Kategorije dokumenata',
  ];

  late final TabController _tabController =
      TabController(length: _tabLabels.length, vsync: this);

  // One provider per entity (created once for this screen).
  final _cityProvider = CityProvider();
  final _countryProvider = CountryProvider();
  final _departmentProvider = DepartmentProvider();
  final _positionProvider = PositionProvider();
  final _contractTypeProvider = ContractTypeProvider();
  final _leaveTypeProvider = LeaveTypeProvider();
  final _legalDocCategoryProvider = LegalDocumentCategoryProvider();

  @override
  void dispose() {
    _tabController.dispose();
    _cityProvider.dispose();
    _countryProvider.dispose();
    _departmentProvider.dispose();
    _positionProvider.dispose();
    _contractTypeProvider.dispose();
    _leaveTypeProvider.dispose();
    _legalDocCategoryProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [for (final l in _tabLabels) Tab(text: l)],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _cities(),
                _countries(),
                _departments(),
                _positions(),
                _contractTypes(),
                _leaveTypes(),
                _documentCategories(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cities() => ReferenceTab<City>(
        title: 'Gradovi',
        singular: 'grad',
        provider: _cityProvider,
        columns: [
          RefColumn('Naziv grada', (c) => c.name, flex: 3),
          RefColumn('Država', (c) => c.countryName, flex: 3),
        ],
        fields: const [
          RefField.text('name', 'Naziv grada', maxLength: 100),
          RefField.fkDropdown(
            'countryId',
            'Država',
            fkEndpoint: '/Countries',
            fkPrereqLabel: 'Države',
          ),
        ],
        toFormValues: (c) => {'name': c.name, 'countryId': c.countryId},
        nameOf: (c) => c.name,
      );

  Widget _countries() => ReferenceTab<Country>(
        title: 'Države',
        singular: 'država',
        provider: _countryProvider,
        columns: [RefColumn('Naziv države', (c) => c.name, flex: 4)],
        fields: const [RefField.text('name', 'Naziv države', maxLength: 100)],
        toFormValues: (c) => {'name': c.name},
        nameOf: (c) => c.name,
      );

  Widget _departments() => ReferenceTab<Department>(
        title: 'Odjeli',
        singular: 'odjel',
        provider: _departmentProvider,
        columns: [RefColumn('Naziv odjela', (d) => d.name, flex: 4)],
        fields: const [RefField.text('name', 'Naziv odjela', maxLength: 100)],
        toFormValues: (d) => {'name': d.name},
        nameOf: (d) => d.name,
      );

  Widget _positions() => ReferenceTab<Position>(
        title: 'Pozicije',
        singular: 'pozicija',
        provider: _positionProvider,
        columns: [
          RefColumn('Naziv pozicije', (p) => p.name, flex: 3),
          RefColumn('Odjel', (p) => p.departmentName, flex: 3),
        ],
        fields: const [
          RefField.text('name', 'Naziv pozicije', maxLength: 100),
          RefField.fkDropdown(
            'departmentId',
            'Odjel',
            fkEndpoint: '/Departments',
            fkPrereqLabel: 'Odjeli',
          ),
        ],
        toFormValues: (p) => {'name': p.name, 'departmentId': p.departmentId},
        nameOf: (p) => p.name,
      );

  Widget _contractTypes() => ReferenceTab<ContractType>(
        title: 'Tipovi ugovora',
        singular: 'tip ugovora',
        provider: _contractTypeProvider,
        columns: [
          RefColumn('Naziv', (t) => t.name, flex: 3),
          RefColumn(
            'Datum završetka obavezan',
            (t) => t.endDateRequired ? 'Da' : 'Ne',
            flex: 3,
          ),
        ],
        fields: const [
          RefField.text('name', 'Naziv', maxLength: 100),
          RefField.boolSwitch('endDateRequired', 'Datum završetka obavezan'),
        ],
        toFormValues: (t) =>
            {'name': t.name, 'endDateRequired': t.endDateRequired},
        nameOf: (t) => t.name,
      );

  Widget _leaveTypes() => ReferenceTab<LeaveType>(
        title: 'Tipovi odsustva',
        singular: 'tip odsustva',
        provider: _leaveTypeProvider,
        columns: [
          RefColumn('Naziv', (t) => t.name, flex: 3),
          RefColumn('Plaćeno', (t) => t.isPaid ? 'Da' : 'Ne', flex: 3),
        ],
        fields: const [
          RefField.text('name', 'Naziv', maxLength: 100),
          RefField.boolSwitch('isPaid', 'Plaćeno odsustvo'),
        ],
        toFormValues: (t) => {'name': t.name, 'isPaid': t.isPaid},
        nameOf: (t) => t.name,
      );

  Widget _documentCategories() => ReferenceTab<LegalDocumentCategory>(
        title: 'Kategorije dokumenata',
        singular: 'kategorija',
        provider: _legalDocCategoryProvider,
        columns: [RefColumn('Naziv kategorije', (c) => c.name, flex: 4)],
        fields: const [
          RefField.text('name', 'Naziv kategorije', maxLength: 150),
        ],
        toFormValues: (c) => {'name': c.name},
        nameOf: (c) => c.name,
      );
}
