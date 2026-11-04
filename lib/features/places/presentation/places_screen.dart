import 'package:flutter/material.dart';

import '../data/places_repository.dart';
import '../models/place.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({required this.loadPlaces, super.key});

  final Future<List<Place>> Function() loadPlaces;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late Future<List<Place>> _places;

  @override
  void initState() {
    super.initState();
    _places = widget.loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sacred Compass')),
      body: FutureBuilder<List<Place>>(
        future: _places,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading places',
              ),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is PlacesLoadException
                          ? error.message
                          : 'Could not load places. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _places = widget.loadPlaces();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final places = snapshot.requireData;
          if (places.isEmpty) {
            return const Center(child: Text('No published places found.'));
          }
          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              final location = [place.country, ?place.region].join(' · ');
              final summary = place.summary;
              return ListTile(
                title: Text(place.name),
                subtitle: Text(
                  summary == null ? location : '$summary\n$location',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
