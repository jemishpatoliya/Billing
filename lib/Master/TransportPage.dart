
import 'package:flutter/material.dart';

class TransportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(labelText: 'Transport Name'),
                ),
              ),
              SizedBox(width: 20),
              ElevatedButton(onPressed: () {}, child: Text('Search')),
              SizedBox(width: 10),
              ElevatedButton(onPressed: () {}, child: Text('Reset'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
            ],
          ),
          SizedBox(height: 20),
          DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Desc')),
              DataColumn(label: Text('Vehicle')),
              DataColumn(label: Text('Entry By')),
              DataColumn(label: Text('Action')),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text('Rajdhani')),
                DataCell(Text('-')),
                DataCell(Text('-')),
                DataCell(Text('MAHADEV ENTERPRISE')),
                DataCell(Row(
                  children: [
                    IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
                    IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
                  ],
                )),
              ])
            ],
          ),
        ],
      ),
    );
  }
}
