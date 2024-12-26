import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, String>>> _newsDataFuture;

  @override
  void initState() {
    super.initState();
    _newsDataFuture = _fetchNewsData();
  }

  Future<List<Map<String, String>>> _fetchNewsData() async {
    final response =
        await http.get(Uri.parse('https://hau.edu.vn/tin-tuc_c01/'));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final newsElements = document.querySelectorAll('.thumbnail-news');

      List<Map<String, String>> newsData = [];

      for (var element in newsElements) {
        final titleElement = element.querySelector('.caption > h3 > a');
        final imageUrlElement = element.querySelector('img');
        final dateElement = element.querySelector('.date');

        String title = titleElement?.text.trim() ?? '';
        String link = titleElement?.attributes['href'] ?? '';

        // Kiểm tra xem link đã là URL đầy đủ chưa
        if (!link.startsWith('http://') && !link.startsWith('https://')) {
          link = 'https://hau.edu.vn$link';
        }

        String imageUrl = imageUrlElement?.attributes['src'] != null
            ? 'https://hau.edu.vn${imageUrlElement?.attributes['src']}'
            : '';
        String date = dateElement?.text.trim() ?? '';

        newsData.add({
          'title': title,
          'link': link,
          'imageUrl': imageUrl,
          'date': date,
        });
      }
      return newsData;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      // Xử lý trường hợp link không hợp lệ, ví dụ hiển thị thông báo lỗi
      return;
    }
    final encodedUrl = Uri.encodeFull(url);
    final uri = Uri.parse(encodedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/img/ic_launcher2.png'),
        title: const Text('HAU News',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color.fromARGB(252, 56, 242, 255),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _newsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final newsData = snapshot.data!;

            return ListView.builder(
              itemCount: newsData.length,
              itemBuilder: (context, index) {
                final item = newsData[index];

                return GestureDetector(
                  onTap: () {
                    if (item['link'] != null && item['link']!.isNotEmpty) {
                      _launchUrl(item['link']!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không có link')),
                      );
                    }
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(item['imageUrl']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Image.network(
                            item['imageUrl']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/img/Hau.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['date'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
