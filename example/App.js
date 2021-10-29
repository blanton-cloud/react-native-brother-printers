/**
 * Sample React Native App
 *
 * adapted from App.js generated by the following command:
 *
 * react-native init example
 *
 * https://github.com/facebook/react-native
 */

import React, {Component} from 'react';
import {Button, Platform, StyleSheet, Text, View} from 'react-native';
import {discoverPrinters} from 'react-native-brother-printers';

export default class App extends Component {
  state = {
    status: 'starting',
    message: '--'
  };

  componentDidMount() {
  }

  render() {
    return (
      <View style={styles.container}>
        <Text>
          Test Connection
        </Text>

        <Button title="Discover Readers" onPress={() => {
          discoverPrinters().then(() => {
            console.log("Discover Successful");
          }).catch(() => {
            console.log("Discover failed")
          });
        }}/>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});
