import SwiftUI

public struct TextFieldStepper: View {
    @Binding var doubleValue: Double
    
    @State private var keyboardOpened = false
    @State private var confirmEdit = false
    @State private var textValue = ""
    @State private var showAlert = false
    @State private var cancelled = false
    @State private var alert: Alert? = nil
    
    private let config: TextFieldStepperConfig
    
    private var cancelButton: some View {
        Button(action: {
            textValue = formatTextValue(doubleValue)
            cancelled = true
            closeKeyboard()
        }) {
            config.declineImage
        }
        .foregroundColor(config.declineImage.color)
    }
    
    private var confirmButton: some View {
        Button(action: {
            validateValue()
        }) {
            config.confirmImage
        }
        .foregroundColor(config.confirmImage.color)
    }
    
    private var decrementButton: some View {
        LongPressButton(
            doubleValue: $doubleValue,
            config: config,
            image: config.decrementImage,
            action: .decrement
        )
    }
    
    private var incrementButton: some View {
        LongPressButton(
            doubleValue: $doubleValue,
            config: config,
            image: config.incrementImage,
            action: .increment
        )
    }
    
    /**
     * init(doubleValue: Binding<Double>, unit: String, label: String, config: TextFieldStepperConfig)
     */
    public init(
        doubleValue: Binding<Double>,
        unit: String? = nil,
        label: String? = nil,
        increment: Double? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        decrementImage: TextFieldStepperImage? = nil,
        incrementImage: TextFieldStepperImage? = nil,
        declineImage: TextFieldStepperImage? = nil,
        confirmImage: TextFieldStepperImage? = nil,
        disabledColor: Color? = nil,
        labelOpacity: Double? = 1.0,
        config: TextFieldStepperConfig = TextFieldStepperConfig()
    ) {
        // Compose config
        var config = config
            config.unit = unit ?? config.unit
            config.label = label ?? config.label
            config.increment = increment ?? config.increment
            config.minimum = minimum ?? config.minimum
            config.maximum = maximum ?? config.maximum
            config.decrementImage = decrementImage ?? config.decrementImage
            config.incrementImage = incrementImage ?? config.incrementImage
            config.declineImage = declineImage ?? config.declineImage
            config.confirmImage = confirmImage ?? config.confirmImage
            config.disabledColor = disabledColor ?? config.disabledColor
            config.labelOpacity = labelOpacity ?? config.labelOpacity
       
        // Assign properties
        self._doubleValue = doubleValue
        self.config = config
        
        // Set text value with State
        _textValue = State(initialValue: formatTextValue(doubleValue.wrappedValue))
    }
    
    public var body: some View {
        HStack {
            ZStack {
                decrementButton.opacity(keyboardOpened ? 0 : 1)
                
                if keyboardOpened {
                    cancelButton
                }
            }
            
            VStack(spacing: 0) {
                TextField("", text: $textValue) { editingChanged in
                    if editingChanged {
                        // Keyboard opened, editing started
                        keyboardOpened = true
                        textValue = textValue.replacingOccurrences(of: config.unit, with: "")
                    } else {
                        keyboardOpened = false
                        
                        // Detect cancel button
                        if cancelled {
                            self.cancelled = false
                            return
                        }
                        
                        validateValue()
                    }
                }
                .multilineTextAlignment(.center)
                .font(.system(size: 24, weight: .black))
                .keyboardType(.decimalPad)
                
                if !config.label.isEmpty {
                    Text(config.label)
                        .font(.footnote)
                        .fontWeight(.light)
                        .opacity(config.labelOpacity)
                }
            }
            
            // Right button
            ZStack {
                incrementButton.opacity(keyboardOpened ? 0 : 1)
                
                if keyboardOpened {
                    confirmButton
                }
            }
        }
        .onChange(of: doubleValue) { _ in
            textValue = formatTextValue(doubleValue)
        }
        .alert(isPresented: $showAlert) {
            alert!
        }
    }
            
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func formatTextValue(_ value: Double) -> String {
        String(format: "%g", value.decimal) + config.unit
    }
    
    func validateValue() {
        // Reset alert status
        showAlert = false
        
        // Confirm doubleValue is actually a Double
        if let textToDouble = Double(textValue) {
            // 4. If doubleValue is less than config.minimum, throw Alert
            // 5. If doubleValue is greater than config.maximum, throw Alert
            if textToDouble.decimal < config.minimum {
                showAlert = true
                alert = Alert(
                    title: Text("Too small!"),
                    message: Text("\(config.label) must be at least \(formatTextValue(config.minimum)).")
                )
                
            }
            
            if textToDouble.decimal > config.maximum {
                showAlert = true
                alert = Alert(
                    title: Text("Too large!"),
                    message: Text("\(config.label) must be at most \(formatTextValue(config.maximum)).")
                )
            }
            
            // All checks passed, set the double value.
            if !showAlert {
                doubleValue = textToDouble
                closeKeyboard()
                
                // If doubleValue is unchanged, ensure the textValue is still formatted
                textValue = formatTextValue(textToDouble)
            }
        } else {
            // 2. If more than one decimal, throw Alert
            // 3. If contains characters, throw Alert (hardware keyboard issue)
            // 6. If doubleValue is empty, throw Alert
            showAlert = true
            alert = Alert(
                title: Text("Whoops!"),
                message: Text("\(config.label) must contain a valid number.")
            )
        }
    }
}
