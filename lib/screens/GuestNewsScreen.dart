import 'package:checkin/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:dart_rss/dart_rss.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GuestNewsScreen extends StatefulWidget {
  const GuestNewsScreen({super.key});

  @override
  State<GuestNewsScreen> createState() => _GuestNewsScreenState();
}

class _GuestNewsScreenState extends State<GuestNewsScreen> {
  late Future<RssFeed> _rssFeed;

  @override
  void initState() {
    super.initState();
    _rssFeed = fetchRssFeed();
  }

  Future<RssFeed> fetchRssFeed() async {
    final response = await http.get(Uri.parse('https://bitexco.com.vn/feed/'));
    if (response.statusCode == 200) {
      final rssFeed = RssFeed.parse(response.body);
      return rssFeed;
    } else {
      throw Exception('Failed to load RSS feed');
    }
  }

  String? extractImageUrl(String content) {
    final document = html_parser.parse(content);
    final imgElement = document.querySelector('img');
    if (imgElement != null) {
      return imgElement.attributes['src'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/img/ic_launcher2.png'),
        title: const Text('HAU News',
            style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: const Color.fromARGB(252, 56, 242, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<RssFeed>(
        future: _rssFeed,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final rssFeed = snapshot.data!;
            return ListView.builder(
              itemCount: rssFeed.items.length,
              itemBuilder: (context, index) {
                final item = rssFeed.items[index];
                final imageUrl = extractImageUrl(item.content!.value);

                return GestureDetector(
                  onTap: () {
                    if (item.link != null) {
                      launchUrl(Uri.parse(item.link!));
                    }
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/img/bitexco2.jpg'),
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
                                item.title ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.pubDate ?? '',
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
