import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidosapp/controllers/branch_controller.dart';
import 'package:pedidosapp/models/branch_model.dart';
import 'package:pedidosapp/utils/dimensions.dart';
import 'package:pedidosapp/widgets/big_text.dart';
import 'package:pedidosapp/widgets/small_text.dart';

import '../../utils/colors.dart';
import '../../routes/route_helper.dart';
import 'food_page_body.dart';

class MainFoodPage extends StatefulWidget {
  const MainFoodPage({super.key});

  @override
  State<MainFoodPage> createState() => _MainFoodPageState();
}

class _MainFoodPageState extends State<MainFoodPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header section
          Container(
            margin: EdgeInsets.only(top: Dimensions.height45, bottom: Dimensions.height15),
            padding: EdgeInsets.only(left: Dimensions.width20, right: Dimensions.width20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GetBuilder<BranchController>(builder: (branchController) {
                  return PopupMenuButton<Branch>(
                    tooltip: "Seleccionar sucursal",
                    onSelected: (Branch branch) {
                      branchController.setBranch(branch.id, branch.name);
                    },
                    itemBuilder: (context) => branchController.branchList.map((branch) {
                      return PopupMenuItem<Branch>(
                        value: branch,
                        child: Text(branch.name, style: const TextStyle(fontFamily: 'Roboto')),
                      );
                    }).toList(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BigText(text: "El Salvador", color: AppColors.mainColor),
                        Row(
                          children: [
                            SmallText(text: branchController.branchName, color: Colors.black54),
                            const Icon(Icons.arrow_drop_down_rounded)
                          ],
                        )
                      ],
                    ),
                  );
                }),
                // Logo centrado
                SizedBox(
                  height: 36.0,
                  child: Image.asset(
                    'assets/image/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(RouteHelper.getSearchPage());
                    },
                    child: Container(
                      width: Dimensions.height45,
                      height: Dimensions.height45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radius15),
                        color: AppColors.mainColor,
                      ),
                      child: Icon(Icons.search, color: Colors.white, size: Dimensions.iconSize24),
                    ),
                  ),
                )
              ],
            ),
          ),
          // Body section
          const Expanded(
            child: SingleChildScrollView(
              child: FoodPageBody(),
            ),
          ),
        ],
      ),
    );
  }
}
