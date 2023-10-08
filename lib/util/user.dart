import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:social_app_ui/util/configs/list_config.dart';
import 'package:social_app_ui/util/sort/map_util.dart';
import 'api.dart';

class RoomieUser {
  String email;
  int tag;
  Map<String, dynamic> essentials, survey;
  String? pushToken;
  int status;

  RoomieUser({
    required this.email,
    this.tag = 0,
    required this.essentials,
    required this.survey,
    String pushToken = '',
    this.status = 0,
  }) : pushToken = pushToken;

  void setPushToken(String token) {
    pushToken = token;
  }

  RoomieUser.init(String email)
      : this.email = email,
        tag = 0,
        status = 0,
        essentials = essentialInitialize(),
        survey = answerInitialize();

  static RoomieUser me = RoomieUser.init(APIs.auth.currentUser!.email!);

  static Map<String, dynamic> essentialInitialize() {
    Map<String, dynamic> init = {};
    init['nickname'] = '';
    init['sex'] = 0;
    init['dormitory'] = '새빛관';
    init['major'] = '공과대학';
    init['studentNumber'] = '23';
    return init;
  }

  static Map<String, dynamic> answerInitialize() {
    Map<String, dynamic> init = {};
    for (var key in answerList.keys) {
      if (key == 'etc') continue;
      init[key] = max((answerList[key]!.length / 2).round() - 1, 0);
    }
    init['etc'] = '';
    return init;
  }

  Map<String, dynamic> getScore(RoomieUser user, Map<String, dynamic> weight) {
    Map<String, double> costs = {};
    Map<String, dynamic> score = {};
    for (var question in questionList) {
      if (question == 'etc') break;
      var diff = ((survey[question] ?? 0) - (user.survey[question] ?? 0)).abs();
      diff = (1 - diff / (answerList[question]!.length - 1)); //normalize
      costs[question] = weight[question]! * diff;
    }
    score['highest'] = getMaxValueKeys(costs, 3);
    score['lowest'] = getMinValueKeys(costs, 3);
    score['total'] = sumMapValues(costs);
    return score;
  }

  factory RoomieUser.fromFirestore(DocumentSnapshot snapshot) {
    var fromFirestore = snapshot.data() as Map<String, dynamic>;
    String email = snapshot.id;
    int tag = fromFirestore['tag'] ?? 0;
    int status = fromFirestore['status'] ?? 0;

    Map<String, dynamic> essentials = {}, survey = {};

    for (var essential in essentialList) {
      essentials[essential] = fromFirestore[essential];
    }
    for (var question in questionList) {
      survey[question] = fromFirestore[question];
    }

    String pushToken = fromFirestore['pushToken'] ?? '';

    return RoomieUser(
      email: email,
      tag: tag,
      essentials: essentials,
      survey: survey,
      pushToken: pushToken,
      status: status,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> toFirestore = {};
    toFirestore['tag'] = tag;
    toFirestore.addAll(essentials);
    toFirestore.addAll(survey);
    toFirestore['pushToken'] = pushToken;
    toFirestore['status'] = status;

    return toFirestore;
  }
}

RoomieUser getUserFromSnapshot(
    AsyncSnapshot<QuerySnapshot<Object?>> snapshot, String email) {
  RoomieUser user = RoomieUser.init(
    email,
  );
  if (snapshot.hasData) {
    for (var doc in snapshot.data!.docs) {
      if (doc.id != email) continue;
      if (doc.id == 'weights') continue;
      user = RoomieUser.fromFirestore(doc);
    }
  }
  return user;
}
