# react-native-brother-printers

React Native Brother Printers is a react-native module that will allow you to interact with the brother printers.

## Getting started

`$ npm install @w3lcome/react-native-brother-printers --save`

or

`$ yarn add @w3lcome/react-native-brother-printers`

### Mostly automatic installation

`$ cd ios; pod install`

or if you are using React Native before version 0.60,

`$ react-native link @w3lcome/react-native-brother-printers`

## iOS Setup

To use this library on iOS, you need to manually add the `BRLMPrinterKit` dependency to your `Podfile`. Add the following line to your `Podfile`:

```ruby
pod 'BRLMPrinterKit', :git => 'https://github.com/blanton-cloud/BRLMPrinterKit.git', :tag => 'v4.12.0'
```

Then, run:

```bash
pod install
```

## Usage

### Discovering a printer

To discover printers use the discoverPrinters function. You can pass in the option parameters `printerName` to change
the printer name, or V6 to enable ipv6 detection. Both parameters can be left blank.

```javascript
import {
  discoverPrinters,
  registerBrotherListener,
} from "@w3lcome/react-native-brother-printers";

discoverPrinters({
  V6: true,
});

registerBrotherListener("onDiscoverPrinters", (printers) => {
  // Store these printers somewhere
});
```

### Printing an image

To print an image, using the `printImage` function, with the first parameter being the printer found during discover,
the second being the uri of the image you want to print, and the third being an objective that contains the label size.

You can find a list of LabelSize and LabelNames inside the package as well.

```javascript
import {printImage, LabelSize} from "@w3lcome/react-native-brother-printers";

await printImage(printer, uri, {labelSize: LabelSize.LabelSizeRollW62RB});
```
