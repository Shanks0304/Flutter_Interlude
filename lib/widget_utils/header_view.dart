import 'package:flutter/material.dart';

class HeaderView extends StatelessWidget {
  const HeaderView({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.08,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(bottom: 10),
            child: RichText(
                text: const TextSpan(
                    text: "INTERLUDE",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    children: <TextSpan>[
                  TextSpan(
                    text: "V1.0",
                    style: TextStyle(color: Colors.red, fontSize: 10),
                  ),
                ])),
          ),
          CircleAvatar(
            radius: 26.5,
            backgroundColor: const Color.fromARGB(255, 42, 102, 45),
            child: ClipOval(
              child: Image.asset(
                "assets/images/uchiha.jpg",
                width: 50.0,
                height: 50.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
