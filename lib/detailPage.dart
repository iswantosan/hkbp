import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  // DetailPage({Key? key, required Posts posts}) : super(key: key);

  final Posts posts;
  const DetailPage({super.key, required this.posts});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Page'),
      ),
      body: SafeArea(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'id: ${posts.id}',
            ),
            Text('Title: ${posts.title}'),
            const SizedBox(
              height: 20,
            ),
            const Text('Body: '),
            Text(posts.body)
          ])),
    );
  }
}