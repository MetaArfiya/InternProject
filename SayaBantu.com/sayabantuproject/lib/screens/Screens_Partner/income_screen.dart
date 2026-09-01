// import 'package:flutter/material.dart';

// import '../../data/dummy_income.dart';


// class IncomeScreen extends StatelessWidget {
//   const IncomeScreen({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {

//     int totalIncome = 0;

//     for (var income in dummyIncome) {
//       totalIncome += int.parse(
//         income.amount
//             .replaceAll("Rp", "")
//             .replaceAll(".", ""),
//       );
//     }

//     return Scaffold(
//       backgroundColor:
//           Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text(
//           "Riwayat Penghasilan",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(30),
//         child: Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//         // TOTAL PENGHASILAN
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [
//                     Color(0xffFF8A00),
//                     Color(0xffF97316),
//                   ],
//                 ),
//                 borderRadius:
//                     BorderRadius.circular(20),
//               ),

//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Total Penghasilan",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 15,
//                     ),
//                   ),

//                   const SizedBox(height: 10),
//                   Text(
//                     "Rp${totalIncome.toString()}",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             const Text(
//               "Riwayat Transaksi",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),

//             Expanded(
//               child: ListView.builder(
//                 itemCount:
//                     dummyIncome.length,
//                 itemBuilder: (context,index){
//                   final income =
//                       dummyIncome[index];
//                   return Container(
//                     margin:
//                         const EdgeInsets.only(
//                           bottom: 15,
//                         ),
//                     padding:
//                         const EdgeInsets.all(18),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius:
//                           BorderRadius.circular(16),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding:
//                               const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color:
//                                 const Color(0xffffedd5),
//                             borderRadius:
//                                 BorderRadius.circular(12),
//                           ),

//                           child: const Icon(
//                             Icons.payments,
//                             color: Colors.orange,
//                           ),
//                         ),

//                         const SizedBox(width: 15),

//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 income.jobTitle,
//                                 style: const TextStyle(
//                                   fontSize: 17,
//                                   fontWeight:
//                                       FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 income.customerName,
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               Text(
//                                 income.date,
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         Text(
//                           income.amount,
//                           style: const TextStyle(
//                             color: Colors.green,
//                             fontWeight:
//                                 FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Digunakan untuk formatting Rupiah

import '../../services/api_service.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<dynamic> _incomes = [];
  int _totalIncome = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIncomeData();
  }

  Future<void> _fetchIncomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 🚀 Endpoint untuk riwayat penghasilan mitra
      final response = await ApiService.get('/mitra/incomes');

      debugPrint("🔎 INCOME STATUS: ${response.statusCode}");
      debugPrint("🔎 INCOME BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> loadedIncomes = [];
        int calculatedTotal = 0;

        if (decodedData is Map<String, dynamic>) {
          // Ambil list transaksi
          var target = decodedData['incomes'] ?? decodedData['data'] ?? [];
          if (target is List) {
            loadedIncomes = target;
          }

          // Jika total penghasilan dikirim langsung dari backend
          if (decodedData.containsKey('total_income')) {
            calculatedTotal = int.tryParse(decodedData['total_income'].toString()) ?? 0;
          } else {
            // Kalkulasi manual jika backend hanya mengirim list transaksi
            for (var item in loadedIncomes) {
              var amountRaw = item['amount'] ?? item['price'] ?? 0;
              if (amountRaw is num) {
                calculatedTotal += amountRaw.toInt();
              } else if (amountRaw is String) {
                String cleaned = amountRaw.replaceAll(RegExp(r'[^0-9]'), '');
                calculatedTotal += int.tryParse(cleaned) ?? 0;
              }
            }
          }
        } else if (decodedData is List) {
          loadedIncomes = decodedData;
          for (var item in loadedIncomes) {
            var amountRaw = item['amount'] ?? item['price'] ?? 0;
            if (amountRaw is num) {
              calculatedTotal += amountRaw.toInt();
            }
          }
        }

        if (mounted) {
          setState(() {
            _incomes = loadedIncomes;
            _totalIncome = calculatedTotal;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat penghasilan (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR INCOME: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan koneksi: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Helper untuk format angka ke Rupiah
  String _formatRupiah(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Riwayat Penghasilan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchIncomeData,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchIncomeData,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CARD TOTAL PENGHASILAN
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xffFF8A00),
                                Color(0xffF97316),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xffF97316).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Penghasilan",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatRupiah(_totalIncome),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Riwayat Transaksi",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // LIST TRANSAKSI PENGHASILAN
                        Expanded(
                          child: _incomes.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 60),
                                    Center(
                                      child: Text(
                                        "Belum ada riwayat penghasilan.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  itemCount: _incomes.length,
                                  itemBuilder: (context, index) {
                                    final income = _incomes[index];

                                    // Mapping data dari JSON Laravel
                                    final String jobTitle = income['job_title'] ?? income['title'] ?? 'Pekerjaan Selesai';
                                    final String customerName = income['customer_name'] ?? income['customer']?['name'] ?? 'Pelanggan';
                                    final String date = income['date'] ?? income['created_at'] ?? '';
                                    
                                    var rawAmount = income['amount'] ?? income['price'] ?? 0;
                                    num numAmount = (rawAmount is num) ? rawAmount : (num.tryParse(rawAmount.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xffE5E7EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffffedd5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.payments,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  jobTitle,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  customerName,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (date.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    date,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatRupiah(numAmount),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}