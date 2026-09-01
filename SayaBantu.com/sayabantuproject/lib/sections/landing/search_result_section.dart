import 'package:flutter/material.dart';
import '../../models/job_model.dart';

class SearchResultSection extends StatelessWidget {
  final List<JobModel> jobs;
  final String keyword;

  const SearchResultSection({
    super.key,
    required this.jobs,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 80,
            vertical: isMobile ? 35 : 50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hasil pencarian \"$keyword\"",
                style: TextStyle(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: isMobile ? 20 : 30,
              ),
              if (jobs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    isMobile ? 30 : 50,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: isMobile ? 60 : 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Pekerjaan tidak ditemukan",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobs.length,
                  itemBuilder: (_, index) {
                    final job = jobs[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 18,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Color(0xffFFF3E8),
                                        child: Icon(
                                          Icons.work_outline,
                                          color: Color(0xffF97316),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          job.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    job.description,
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  // PERBAIKAN DI SINI (Mobile)
                                  Text(
                                    job.location ?? "Lokasi tidak tersedia",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    job.price,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  const Text(
                                    "Mencari Mitra",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xffFFF3E8),
                                  child: Icon(
                                    Icons.work_outline,
                                    color: Color(0xffF97316),
                                  ),
                                ),
                                title: Text(job.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.description,
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    // PERBAIKAN DI SINI (Desktop/ListTile)
                                    Text(
                                      job.location ?? "Lokasi tidak tersedia",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      job.price,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    const Text(
                                      "Mencari Mitra",
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                )
            ],
          ),
        );
      },
    );
  }
}