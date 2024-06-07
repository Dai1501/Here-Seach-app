import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HERE Search App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];

  void _search(String query) async {
    const apiKey = 'APVvIoGFNLKURH5tPQFyNvErtg1ztf2AqlBVSYRzPk4';
    final url = 'https://autocomplete.search.hereapi.com/v1/autocomplete?q=$query&apiKey=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _results = data['items'];
      });
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  void _openGoogleMaps(String address) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$address';
    try {
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } catch (error) {
      print('Error launching Google Maps: $error');
    }
  }

  Widget _highlightText(String text, String query) {
    final RegExp regex = RegExp('($query)', caseSensitive: false);
    final Iterable<Match> matches = regex.allMatches(text);
    final List<TextSpan> children = [];

    int lastMatchEnd = 0;
    for (Match match in matches) {
      final String beforeMatch = text.substring(lastMatchEnd, match.start);
      if (beforeMatch.isNotEmpty) {
        children.add(TextSpan(text: beforeMatch));
      }
      final String matchText = text.substring(match.start, match.end);
      children.add(TextSpan(text: matchText, style: TextStyle(fontWeight: FontWeight.bold)));
      lastMatchEnd = match.end;
    }

    final String remainingText = text.substring(lastMatchEnd);
    if (remainingText.isNotEmpty) {
      children.add(TextSpan(text: remainingText));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.black),
        children: children,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HERE Search App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
              onChanged: (query) {
                if (query.length >= 2) {
                  _search(query);
                } else {
                  setState(() {
                    _results = [];
                  });
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final title = result['title'];
                  final address = result['address']['label'];
                  final query = _controller.text;

                  return ListTile(
                    title: _highlightText(address, query),
                    trailing: IconButton(
                      icon: Icon(Icons.directions),
                      onPressed: () {
                        print(address);
                        _openGoogleMaps(address);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
