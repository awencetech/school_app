import 'package:flutter/material.dart';

import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentUniformRequestPage extends StatefulWidget {
  const StudentUniformRequestPage({super.key});

  @override
  State<StudentUniformRequestPage> createState() => _StudentUniformRequestPageState();
}

class _StudentUniformRequestPageState extends State<StudentUniformRequestPage> {
  bool _showOrder = false;

  final List<_MeasurementField> _measurementFields = const [
    _MeasurementField('Neck', '13.8'),
    _MeasurementField('Shoulder Width', '0cm or 0.0in'),
    _MeasurementField('Chest', '0cm or 0.0in'),
    _MeasurementField('Waist', '0cm or 0.0in'),
    _MeasurementField('Sleeve', '0cm or 0.0in'),
    _MeasurementField('Jacket length', '0cm or 0.0in'),
    _MeasurementField('Bicep', '0cm or 0.0in'),
    _MeasurementField('Wrist', '0cm or 0.0in'),
    _MeasurementField('Hip/Lower Waist', '0cm or 0.0in'),
    _MeasurementField('Inseam/Inside leg', '0cm or 0.0in'),
    _MeasurementField('Outside Leg', '0cm or 0.0in'),
    _MeasurementField('Rise', '0cm or 0.0in'),
    _MeasurementField('Thigh', '0cm or 0.0in'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff34395f),
        elevation: 0,
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          'SAMUNI',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: _showOrder ? _buildOrderView() : _buildMeasureView(),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildMeasureView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Text(
            'Measure & Uniform Request',
            style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffd8d8d8)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showOrder = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xffd8d8d8)),
                      ),
                    ),
                    child: const Text(
                      'Measure',
                      style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showOrder = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: const Text(
                      'Order',
                      style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            'Measurement Details',
            style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            'Can we get MOHAMED AZEEMSHA A measurement? This will help us plan the uniforms more efficiently. Take measurement and enter the values to be stored. We can also confirm details with you over phone.\n\nLast measured: 20-Nov-25',
            style: TextStyle(fontSize: 10, color: Color(0xff555555)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            itemCount: _measurementFields.length,
            itemBuilder: (context, index) {
              final field = _measurementFields[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${field.label} (${field.value})',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xff2f2f2f),
                            ),
                          ),
                        ),
                        const Icon(Icons.info_outline, size: 12, color: Color(0xff1e88e5)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 24,
                      child: TextFormField(
                        initialValue: field.value,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xff4ba3ff)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xff4ba3ff)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Color(0xff4ba3ff)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderView() {
    final orders = [
      _UniformOrder(
        code: 'SPORTS_T',
        description: 'Sports T-Shirt',
        size: '32',
        nos: '1',
        date: '13 Apr',
        status: 'Given',
        delivery: '10 Apr 23',
      ),
      _UniformOrder(
        code: 'SPORTS_PANT',
        description: 'Sports Pant',
        size: '34',
        nos: '1',
        date: '15 Apr',
        status: 'Given',
        delivery: '10 Apr 23',
      ),
      _UniformOrder(
        code: 'AHRA_TSHIRT',
        description: 'AHRA T-shirt',
        size: '20',
        nos: '1',
        date: '15 Jun',
        status: 'Given',
        delivery: '14 Jun 23',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Text(
            'Measure & Uniform Request',
            style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffd8d8d8)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showOrder = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xffd8d8d8)),
                      ),
                    ),
                    child: const Text(
                      'Measure',
                      style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showOrder = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xffeef4ff),
                    ),
                    child: const Text(
                      'Order',
                      style: TextStyle(fontSize: 12, color: Color(0xff1d3557)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            'Uniform Requested',
            style: TextStyle(fontSize: 11, color: Color(0xff1d3557)),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xfff5f5f5)),
                columnSpacing: 16,
                horizontalMargin: 12,
                border: TableBorder.all(color: const Color(0xffd8d8d8)),
                columns: const [
                  DataColumn(label: Text('Dress Code', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Description', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Size', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Nos', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Date', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Status', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('Approx\nDelivery\nDate', style: TextStyle(fontSize: 9))),
                ],
                rows: orders
                    .map(
                      (order) => DataRow(
                        cells: [
                          DataCell(Text(order.code, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.description, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.size, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.nos, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.date, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.status, style: const TextStyle(fontSize: 8))),
                          DataCell(Text(order.delivery, style: const TextStyle(fontSize: 8))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasurementField {
  const _MeasurementField(this.label, this.value);

  final String label;
  final String value;
}

class _UniformOrder {
  const _UniformOrder({
    required this.code,
    required this.description,
    required this.size,
    required this.nos,
    required this.date,
    required this.status,
    required this.delivery,
  });

  final String code;
  final String description;
  final String size;
  final String nos;
  final String date;
  final String status;
  final String delivery;
}
