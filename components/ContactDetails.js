import React, { useState } from "react";
import {
  StyleSheet,
  Text,
  View,
  SectionList,
  TouchableOpacity,
} from "react-native";

export default function ContactDetails({ navigation, route }) {
  return (
    <View style={styles.container}>
      <Text>
        <Text>First part and </Text>
        <Text>second part</Text>
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    flexDirection: "row",
    alignSelf: "stretch",
  },
});
