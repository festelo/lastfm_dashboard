import 'package:flutter/material.dart';

class _ArtistInfo {
  String name;
  String image;
  int scrobbles;
  Color selectionColor;

  _ArtistInfo({
    this.name,
    this.image,
    this.scrobbles,
    this.selectionColor
  });
}

class ArtistsList extends StatefulWidget {
  @override
  _ArtistsListState createState() => _ArtistsListState();
}

class _ArtistsListState extends State<ArtistsList> {
  static const msiImage = "https://lastfm.freetls.fastly.net/i/u/770x0/e9b435adf77c4cc2ac4d9ff6ce2d3b9e.webp#e9b435adf77c4cc2ac4d9ff6ce2d3b9e";
  static const mansonImage = "https://lastfm.freetls.fastly.net/i/u/770x0/cbf5083cc1244b36cb8ef0810528670f.webp#cbf5083cc1244b36cb8ef0810528670f";
  
  var counter = 0;

  final artistsArray = [
    _ArtistInfo(
      image: mansonImage,
      name: "Marilyn Manson",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: msiImage,
      name: "Mindless Self Indulgence",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: msiImage,
      name: "Mindless Self Indulgence",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: msiImage,
      name: "Mindless Self Indulgence",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: msiImage,
      name: "Mindless Self Indulgence",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: mansonImage,
      name: "Marilyn Manson",
      scrobbles: 12345,
    ),
    _ArtistInfo(
      image: mansonImage,
      name: "Marilyn Manson",
      scrobbles: 12345,
    ),
  ];

  Widget listItem({
    String name, 
    String image, 
    int scrobbles,
    Color selectionColor,
    VoidCallback onPressed
  }) => FlatButton(
    onPressed: onPressed,
    padding: EdgeInsets.all(0),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Container(
            color: selectionColor,
            height: 44,
            width: 2,
          ),
          SizedBox(width: 10,),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectionColor
            ),
            height: 46,
            width: 46,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(image),
                  ),
                ),
                if (selectionColor != null)
                Center(
                  child: Icon(
                    Icons.check,
                    color: selectionColor,
                    size: 40,
                  ),
                ),
              ]
            )
          ),
          SizedBox(width: 20,),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name,
                  style: Theme.of(context).textTheme.subhead,
                ),
                Text('$scrobbles scrobbles',
                  style: Theme.of(context).textTheme.caption,
                )
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {},
          ),
          SizedBox(width: 12,),
        ],
      ),
    )
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: 10
          ),
          itemCount: artistsArray.length,
          itemBuilder: (_, i) => listItem(
            image: artistsArray[i].image,
            name: artistsArray[i].name,
            scrobbles: artistsArray[i].scrobbles,
            selectionColor: artistsArray[i].selectionColor,
            onPressed: () => setState(() => 
              artistsArray[i].selectionColor = [
                Colors.red,
                Colors.green,
                Colors.orange,
                Colors.yellow,
                null
              ][counter++ % 5]
            )
          ),
        )
      )
    );
  }
}