# Swift project checks

project := "ios/ChecklistApp.xcodeproj"
scheme := "ChecklistApp"
configuration := "Debug"
derived_data_path := "build/dev"
build_ios_derived_data_path := "build/device"
simulator_id := "56C3E671-5A35-4C9B-A6DA-AC9512AF3291"
device_id := "9FF18E4A-B60F-55D9-A415-7D4C147C861D"

[parallel]
check: format build-sim

format:
    ./scripts/format-swift

format-check:
    git ls-files -z '*.swift' | xargs -0 swiftformat --lint

[parallel]
check-push: format-check build-ios

build:
    ./scripts/build-debug

build-ios:
    xcodebuildmcp device build --project-path {{project}} --scheme {{scheme}} --configuration {{configuration}} --derived-data-path {{build_ios_derived_data_path}}

build-ios-xcodebuild:
    ./scripts/build-ios-debug

build-sim:
    xcodebuildmcp simulator build --project-path {{project}} --scheme {{scheme}} --configuration {{configuration}} --simulator-id {{simulator_id}} --derived-data-path {{derived_data_path}}

dev simulator="iPhone 17 Pro":
    ./scripts/run-ios-dev "{{simulator}}"

dev-ios sim_id=simulator_id:
    xcodebuildmcp simulator build-and-run --project-path {{project}} --scheme {{scheme}} --configuration {{configuration}} --simulator-id {{sim_id}} --derived-data-path {{derived_data_path}}

dev-ios-device dev_id=device_id:
    xcodebuildmcp device build-and-run --project-path {{project}} --scheme {{scheme}} --configuration {{configuration}} --device-id {{dev_id}} --derived-data-path {{derived_data_path}}

run-device:
    ./scripts/run-ios-device

screenshot sim_id=simulator_id:
    xcodebuildmcp simulator screenshot --simulator-id {{sim_id}}

snapshot-ui sim_id=simulator_id:
    xcodebuildmcp simulator snapshot-ui --simulator-id {{sim_id}}

list-simulators:
    xcodebuildmcp simulator list

list-devices:
    xcodebuildmcp device list

schemes:
    xcodebuildmcp project-discovery list-schemes --project-path {{project}}

settings:
    xcodebuildmcp project-discovery show-build-settings --project-path {{project}} --scheme {{scheme}}
