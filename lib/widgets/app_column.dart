import 'package:flutter/material.dart';
import 'package:pedidosapp/widgets/small_text.dart';
import '../utils/colors.dart';
import '../utils/dimensions.dart';
import 'big_text.dart';
import 'icon_and_text_widget.dart';

class AppColumn extends StatelessWidget {
  final String text;
  final double stars;
  final String category;
  final String? timePreparation;

  const AppColumn({
    super.key,
    required this.text,
    this.stars = 5.0,
    this.category = "General",
    this.timePreparation,
  });

  @override
  Widget build(BuildContext context) {
    // estado para tiempo de preparación
    int time = int.tryParse(timePreparation ?? "32") ?? 32;
    String speedText;
    Color speedColor;

    if (time >= 10 && time <= 20) {
      speedText = "Rápido";
      speedColor = Colors.green;
    } else if (time >= 21 && time <= 40) {
      speedText = "Normal";
      speedColor = AppColors.iconColor1;
    } else {
      speedText = "Tardado";
      speedColor = Colors.redAccent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BigText(text: text, size: Dimensions.font26),
        SizedBox(height: Dimensions.height10),
        Row(
          children: [
            Wrap(
              children: List.generate(
                stars.floor(),
                (index) => Icon(Icons.star, color: AppColors.mainColor, size: 15),
              ),
            ),
            const SizedBox(width: 10),
            SmallText(text: stars.toString()),
            const SizedBox(width: 10),
             SmallText(text: "1287"),
            const SizedBox(width: 10),
            SmallText(text: "comments"),
          ],
        ),
        SizedBox(height: Dimensions.height20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconAndTextWidget(
              icon: Icons.circle_sharp,
              text: speedText,
              iconColor: speedColor,
            ),
            IconAndTextWidget(
              icon: Icons.location_on,
              text: "1.7km",
              iconColor: AppColors.mainColor,
            ),
            IconAndTextWidget(
              icon: Icons.access_time_rounded,
              text: "${timePreparation ?? "32"} min",
              iconColor: AppColors.iconColor2,
            )
          ],
        )
      ],
    );
  }
}
