# ML Piece Selection Model Implementation Plan

## Overview

Implement a simplified machine learning model using Create ML to improve piece selection in BlockBomb. The system will collect gameplay data from 5-10 devices, train models offline, and provide real-time on-device inference to extend game duration.

## Phase 1: Simple Data Collection

### Task 1.1: Direct CSV Data Logger

**Objective**: Create CSV logging system for immediate Create ML compatibility

**AI Prompt:**

```
Create a CSV gameplay data logging system for the BlockBomb iOS game:

Requirements:
- [ ] Create GameplayDataLogger class in `/Features/ML/GameplayDataLogger.swift`
- [ ] Log directly to CSV format for Create ML compatibility
- [ ] Include headers: board_state, available_pieces, selected_piece, score_delta, lines_cleared, game_duration
- [ ] Flatten board state to comma-separated values
- [ ] Encode available pieces as binary features
- [ ] Append each move to CSV file in Documents directory
- [ ] Add session metadata (session_id, timestamp)

Technical Specifications:
- CSV format: direct Create ML input compatibility
- Board state: flattened 2D array as "0,1,0,1,..." string
- Available pieces: binary encoding "1,0,1,0,..." for each piece type
- Selected piece: piece type ID
- File location: Documents/gameplay_data.csv
- Auto-flush after each write for data safety

File Locations:
- `/Features/ML/GameplayDataLogger.swift`
- `/Models/GameplaySession.swift`

Integration Points:
- GameController for game state access
- PieceManager for piece selection events

Requirements:
- [ ] Create GameplayDataLogger for direct CSV logging
- [ ] Flatten board state and encode pieces for CSV
- [ ] Log each move immediately to CSV file
- [ ] Add session tracking with timestamps

Return to ml_piece_model.md and mark the requirements complete. Do not implement new sections without my permission.
```

**User Intervention**: Test CSV format by opening file in spreadsheet app

**Build & Test**: Build and run the app to verify CSV logging

### Task 1.2: Direct CSV Upload to S3

**Objective**: Upload CSV files directly to S3 bucket

**AI Prompt:**

```
Create direct CSV upload to AWS S3 bucket for the BlockBomb iOS game:

Requirements:
- [ ] Add AWS SDK for iOS to project dependencies
- [ ] Create S3Uploader class in `/Features/ML/S3Uploader.swift`
- [ ] Upload CSV files directly to 'bemuplogs' S3 bucket
- [ ] Add timestamp to filename for versioning
- [ ] Add basic retry logic for failed uploads
- [ ] Keep local CSV file for backup
- [ ] Add manual upload trigger for testing
- [ ] Configure AWS credentials and region

Technical Specifications:
- AWS SDK for iOS integration
- S3 bucket: 'bemuplogs'
- Filename format: "gameplay_data_YYYYMMDD_HHMMSS.csv"
- Simple retry mechanism (3 attempts)
- Keep local file after upload for continued logging
- Manual upload button for testing
- AWS credentials configuration

File Locations:
- `/Features/ML/S3Uploader.swift`
- `/Configuration/AWSConfig.swift`

Integration Points:
- GameplayDataLogger for CSV file source
- AWS S3 for file uploads

Requirements:
- [ ] Add AWS SDK and configure S3 credentials
- [ ] Create S3Uploader for direct CSV uploads to bemuplogs bucket
- [ ] Add retry logic and timestamped filenames
- [ ] Add manual upload trigger for testing

Return to ml_piece_model.md and mark the requirements complete. Do not implement new sections without my permission.
```

**User Intervention**: Configure AWS credentials and S3 bucket permissions for bemuplogs

**Build & Test**: Build and run the app to verify S3 integration

## Phase 2: Model Training Setup

### Task 2.1: Manual Data Download

**Objective**: Manual CSV file collection for Create ML training

**User Intervention**:
**Manual CSV Collection Steps:**

1. Download all CSV files from S3 'bemuplogs' bucket via AWS console
2. Open each CSV file to verify data quality
3. Manually combine CSV files in spreadsheet app if needed
4. Save final dataset as single CSV for Create ML training
5. Review data statistics (row count, completeness)

**Build & Test**: Verify final CSV format is ready for Create ML

### Task 2.2: Create ML Model Training

**Objective**: Train model using Create ML framework

**User Intervention**:
**Manual Create ML Training Steps:**

1. Open Create ML app on macOS
2. Create new Tabular Classifier project
3. Import the merged CSV file from DataProcessor
4. Set target column to game duration improvement
5. Configure training parameters:
   - Algorithm: Boosted Tree or Random Forest
   - Validation split: 80/20
   - Max iterations: 100
6. Train the model and review metrics
7. Export as .mlmodel file for Core ML
8. Test model performance on validation set
9. Iterate on features if accuracy is low
10. Save final model to project bundle

**Build & Test**: Validate exported .mlmodel file loads correctly

## Phase 3: Core ML Integration

### Task 3.1: Core ML Model Integration

**Objective**: Integrate trained Core ML model for on-device inference

**AI Prompt:**

```

Integrate Core ML model for real-time piece selection in BlockBomb iOS game:

Requirements:

- [ ] Create CoreMLModelManager in `/Features/ML/Inference/`
- [ ] Implement model loading and initialization
- [ ] Add real-time inference for piece selection
- [ ] Create feature preprocessing for inference
- [ ] Implement prediction caching for performance
- [ ] Add fallback logic for model failures
- [ ] Create model update mechanism
- [ ] Add inference performance monitoring

Technical Specifications:

- Core ML framework for on-device inference
- Real-time prediction < 100ms response time
- Background preprocessing for immediate response
- Prediction caching for repeated scenarios
- Graceful fallback to rule-based selection
- Model hot-swapping for updates

File Locations:

- `/Features/ML/Inference/CoreMLModelManager.swift`
- `/Features/ML/Inference/PredictionEngine.swift`
- `/Features/ML/Inference/FeaturePreprocessor.swift`
- `/Features/ML/Inference/PredictionCache.swift`

Accessibility:

- No impact on game responsiveness
- Error handling for model loading issues
- Performance monitoring for optimization

Integration Points:

- PieceManager for piece selection integration
- GameController for game state access
- Performance monitoring systems

Requirements:

- [ ] Create CoreMLModelManager for model integration
- [ ] Implement real-time inference < 100ms
- [ ] Add feature preprocessing for Core ML
- [ ] Create prediction caching system
- [ ] Add fallback logic for failures
- [ ] Implement model update mechanism

Return to ml_piece_model.md and mark the requirements complete. Do not implement new sections without my permission.
```

**User Intervention**: Test inference performance on target devices

**Build & Test**: Build and run the app to verify Core ML integration

## Phase 4: Basic Testing

### Task 4.1: Simple Unit Tests

**Objective**: Basic tests for ML components

**AI Prompt:**

```
Create basic unit tests for ML system components:

Requirements:
- [ ] Test GameplayDataLogger data capture
- [ ] Test MLPieceSelector model loading
- [ ] Test feature extraction accuracy
- [ ] Test fallback logic when model fails
- [ ] Mock Core ML model for testing

File Locations:
- `/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/GameplayDataLoggerTests.swift`
- `/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/MLPieceSelectorTests.swift`

Requirements:
- [ ] Test core ML functionality
- [ ] Test data logging accuracy
- [ ] Test model integration and fallback

Return to ml_piece_model.md and mark the requirements complete. Do not implement new sections without my permission.
```

### Task 4.2: Performance Validation

**Objective**: Ensure ML system doesn't impact game performance

**AI Prompt:**

```
Validate ML system performance impact on game:

Requirements:
- [ ] Measure inference time for piece selection
- [ ] Test memory usage with ML components
- [ ] Validate performance on iOS 15 devices
- [ ] Test battery usage impact
- [ ] Ensure smooth gameplay with ML enabled

Technical Specifications:
- Target inference time: < 100ms
- Memory usage monitoring
- Battery usage measurement
- Performance testing on older devices

File Locations:
- `/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/Performance/MLPerformanceTests.swift`

Requirements:
- [ ] Measure and optimize inference performance
- [ ] Test on target iOS 15+ devices
- [ ] Validate smooth gameplay experience

Return to ml_piece_model.md and mark the requirements complete. Do not implement new sections without my permission.
```

## Implementation Order

1. **Data Foundation** (Phase 1): Data collection, Firebase integration, and privacy
2. **Model Development** (Phase 2): Training pipeline, Create ML integration, and evaluation
3. **Production Integration** (Phase 3): Core ML deployment, intelligent selection, and monitoring
4. **Quality Assurance** (Phase 4): Testing, optimization, and validation

## New File Structure Changes

### New Files:

```
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Features/ML/GameplayDataLogger.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Features/ML/S3Uploader.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Configuration/AWSConfig.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Features/ML/MLPieceSelector.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Features/ML/ABTestManager.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Models/GameplaySession.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbomb/Resources/ML/PieceSelectionModel.mlmodel
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/GameplayDataLoggerTests.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/MLPieceSelectorTests.swift
/Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/Performance/MLPerformanceTests.swift
```

### Core Components:

- `GameplayDataLogger.swift` - Direct CSV gameplay data collection
- `S3Uploader.swift` - CSV file upload to S3 bemuplogs bucket
- `MLPieceSelector.swift` - Core ML piece selection
- `ABTestManager.swift` - Simple ML vs baseline comparison

### Configuration:

- AWS SDK integration for S3 uploads
- S3 bucket configuration for bemuplogs
- AWS credentials setup for file uploads
- A/B testing configuration for model evaluation
- Performance tests: iOS 15+ device compatibility
- A/B testing: Model effectiveness validation

### Privacy and Compliance:

- Anonymous data collection with user consent
- Clear privacy policy for ML data usage
- Data deletion capabilities for users
- GDPR and privacy regulation compliance
  /Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/GameplayDataLoggerTests.swift
  /Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/ML/MLPieceSelectorTests.swift
  /Users/robertjohnson/CodeAppsIOS/blockbomb/blockbombTests/Performance/MLPerformanceTests.swift

### New Core Components:

- `GameplayDataLogger.swift` - Anonymous gameplay data collection
- `FirebaseDataManager.swift` - Cloud data storage and sync
- `CoreMLModelManager.swift` - On-device ML inference
- `IntelligentPieceSelector.swift` - ML-powered piece selection

### Configuration Extensions:

- Firebase configuration for anonymous data collection
- Core ML model deployment and versioning
- Privacy settings for data collection consent
- Performance monitoring and alerting

### Test Coverage:

- Unit tests: 95% coverage for ML components
- Integration tests: End-to-end ML workflow validation
- Performance tests: iOS 15+ device compatibility
- A/B testing: Model effectiveness validation

### Privacy and Compliance:

- Anonymous data collection with user consent
- Clear privacy policy for ML data usage
- Data deletion capabilities for users
- GDPR and privacy regulation compliance
- [ ] Optimize memory usage for ML components
- [ ] Test performance on older iOS devices (iOS 15+)
- [ ] Validate battery usage impact
- [ ] Optimize model size and inference speed
- [ ] Create performance benchmarking suite

Technical Specifications:

- Target inference time: < 100ms
- Memory usage optimization for older devices
- Battery usage monitoring and optimization
- Model size optimization without accuracy loss
- Performance validation on target device range

File Locations:

- `/Tests/Performance/ML/MLPerformanceTests.swift`
- `/Tests/Performance/ML/DeviceCompatibilityTests.swift`
- `/Tools/ML/PerformanceBenchmark.swift`

Validation Metrics:

- Game duration improvement percentage
- Inference time consistency
- Memory and battery usage impact
- User experience quality metrics

Requirements:

- [ ] Profile and optimize Core ML inference
- [ ] Validate game duration improvements
- [ ] Test performance on iOS 15+ devices
- [ ] Optimize memory and battery usage
- [ ] Create performance benchmarking
- [ ] Validate user experience improvements
