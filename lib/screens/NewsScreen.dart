import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  // Màn hình hiển thị tin tức
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // Khai báo các biến trạng thái
  late Future<List<Map<String, String>>>
      _newsDataFuture; // Future để lấy dữ liệu tin tức

  @override
  void initState() {
    // Hàm initState được gọi khi widget được khởi tạo
    super.initState();
    _newsDataFuture =
        _fetchNewsData(); // Gọi hàm lấy dữ liệu tin tức khi widget được khởi tạo
  }

  Future<List<Map<String, String>>> _fetchNewsData() async {
    // Hàm lấy dữ liệu tin tức từ trang web
    final response = await http.get(Uri.parse(
        'https://hau.edu.vn/tin-tuc_c01/')); // Gọi API để lấy nội dung trang web

    if (response.statusCode == 200) {
      // Nếu gọi API thành công
      final document = html_parser.parse(response.body); // Parse HTML
      final newsElements = document.querySelectorAll(
          '.thumbnail-news'); // Chọn tất cả các element chứa tin tức

      List<Map<String, String>> newsData =
          []; // Tạo danh sách để lưu trữ dữ liệu tin tức

      for (var element in newsElements) {
        // Duyệt qua từng element chứa tin tức
        final titleElement = element
            .querySelector('.caption > h3 > a'); // Lấy element chứa tiêu đề
        final imageUrlElement =
            element.querySelector('img'); // Lấy element chứa ảnh
        final dateElement =
            element.querySelector('.date'); // Lấy element chứa ngày đăng

        String title = titleElement?.text.trim() ??
            ''; // Lấy tiêu đề, loại bỏ khoảng trắng thừa
        String link =
            titleElement?.attributes['href'] ?? ''; // Lấy link, có thể null

        // Kiểm tra xem link đã là URL đầy đủ chưa
        if (!link.startsWith('http://') && !link.startsWith('https://')) {
          link =
              'https://hau.edu.vn$link'; // Nếu link không có http hoặc https thì thêm vào
        }

        String imageUrl = imageUrlElement?.attributes['src'] !=
                null // Lấy link ảnh, có thể null
            ? 'https://hau.edu.vn${imageUrlElement?.attributes['src']}'
            : '';
        String date =
            dateElement?.text.trim() ?? ''; // Lấy ngày đăng, có thể null

        newsData.add({
          // Thêm dữ liệu tin tức vào danh sách
          'title': title,
          'link': link,
          'imageUrl': imageUrl,
          'date': date,
        });
      }
      return newsData; // Trả về danh sách dữ liệu tin tức
    } else {
      throw Exception('Failed to load data'); // Nếu gọi API thất bại, ném lỗi
    }
  }

  Future<void> _launchUrl(String url) async {
    // Hàm mở link tin tức
    if (url.isEmpty) {
      // Xử lý trường hợp link không hợp lệ, ví dụ hiển thị thông báo lỗi
      return;
    }
    final encodedUrl = Uri.encodeFull(url); // Encode URL
    final uri = Uri.parse(encodedUrl);
    if (await canLaunchUrl(uri)) {
      // Nếu có thể mở link
      await launchUrl(uri,
          mode: LaunchMode.externalApplication); // Mở link bằng ứng dụng ngoài
    } else {
      // Xử lý khi không mở được link (có thể thêm thông báo lỗi)
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hàm build giao diện người dùng
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
            'assets/img/ic_launcher2.png'), // Hiển thị logo ở appbar
        title: const Text('HAU News', // Hiển thị tiêu đề appbar
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor:
            const Color.fromARGB(252, 56, 242, 255), // Màu background appbar
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _newsDataFuture, // Future để lấy dữ liệu
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Nếu có dữ liệu
            final newsData = snapshot.data!; // Lấy dữ liệu tin tức

            return ListView.builder(
              itemCount: newsData.length,
              itemBuilder: (context, index) {
                final item = newsData[index]; // Lấy dữ liệu của từng tin tức

                return GestureDetector(
                  onTap: () {
                    // Hàm xử lý khi click vào tin tức
                    if (item['link'] != null && item['link']!.isNotEmpty) {
                      _launchUrl(item['link']!); // Mở link
                    } else {
                      // Nếu không có link thì hiển thị thông báo
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
                              image: NetworkImage(
                                  item['imageUrl']!), // Hiển thị ảnh tin tức
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Image.network(
                            item['imageUrl']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/img/Hau.png', // Hiển thị ảnh placeholder nếu ảnh lỗi
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
              child: Text(
                  'Error: ${snapshot.error}'), // Nếu có lỗi thì hiển thị thông báo lỗi
            );
          } else {
            return const Center(
              child:
                  CircularProgressIndicator(), // Nếu đang loading thì hiển thị loading
            );
          }
        },
      ),
    );
  }
}
