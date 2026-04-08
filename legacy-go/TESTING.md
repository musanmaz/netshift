# Testing Guide

Bu doküman DNS Helper projesinin test stratejisini ve nasıl test edileceğini açıklar.

## 🧪 Test Yapısı

```
dns-helper/
├── internal/
│   ├── bench/
│   │   ├── bench.go
│   │   └── bench_test.go          # Benchmark testleri
│   ├── cli/
│   │   ├── *.go
│   │   └── cli_test.go            # CLI testleri
│   ├── platform/
│   │   ├── dns_*.go
│   │   └── platform_test.go       # Platform testleri
│   ├── resolvers/
│   │   ├── presets.go
│   │   └── presets_test.go        # Resolver testleri
│   ├── util/
│   │   ├── shell.go
│   │   └── shell_test.go          # Utility testleri
│   ├── integration_test.go        # Integration testleri
│   └── test_helpers.go            # Test yardımcıları
├── test_config.go                  # Test konfigürasyonu
└── TESTING.md                     # Bu dosya
```

## 🚀 Hızlı Başlangıç

### Tüm Testleri Çalıştır
```bash
make test
```

### Sadece Unit Testler
```bash
make test-unit
```

### Sadece Integration Testler
```bash
make test-integration
```

### Race Detection ile Test
```bash
make test-race
```

### Coverage Raporu ile Test
```bash
make test-coverage
```

## 📋 Test Kategorileri

### 1. **Unit Tests** (`test-unit`)
- **Resolvers**: DNS preset'lerinin doğruluğu
- **Bench**: Benchmark hesaplamaları
- **Util**: Shell komut çalıştırma
- **CLI**: Komut yapısı ve flag'ler

### 2. **Integration Tests** (`test-integration`)
- **Benchmark**: Gerçek DNS sunucuları ile test
- **Resolvers**: Gerçek resolver verileri ile test
- **Timeout**: Zaman aşımı davranışı

### 3. **Platform Tests** (`test-platform`)
- **macOS**: `networksetup` komutları
- **Linux**: `resolvectl` ve `nmcli`
- **Windows**: PowerShell komutları

## 🔧 Test Konfigürasyonu

### Environment Variables
```bash
# Network testlerini atla
export DNS_HELPER_SKIP_NETWORK=true

# Yavaş testleri atla
export DNS_HELPER_SKIP_SLOW=true

# Debug çıktısı
export DNS_HELPER_DEBUG=true

# Test timeout
export DNS_HELPER_TIMEOUT=60s
```

### Test Flags
```bash
# Verbose output
go test -v ./...

# Race detection
go test -race ./...

# Coverage
go test -coverprofile=coverage.out ./...

# Benchmark
go test -bench=. ./...

# Short tests only
go test -short ./...
```

## 🎯 Test Senaryoları

### Resolvers Test
```bash
# Preset'lerin varlığını kontrol et
go test -v ./internal/resolvers -run TestPresets

# DNS sunucu içeriğini kontrol et
go test -v ./internal/resolvers -run TestPresetContent

# Sıralamayı kontrol et
go test -v ./internal/resolvers -run TestPresetOrder
```

### Benchmark Test
```bash
# Sonuç metodlarını test et
go test -v ./internal/bench -run TestResultMethods

# Percentile hesaplamalarını test et
go test -v ./internal/bench -run TestPercentileCalculation

# Edge case'leri test et
go test -v ./internal/bench -run TestPercentileEdgeCases
```

### Utility Test
```bash
# Shell komut çalıştırmayı test et
go test -v ./internal/util -run TestRunWithTimeout

# Hata durumlarını test et
go test -v ./internal/util -run TestRunWithError

# Timeout davranışını test et
go test -v ./internal/util -run TestRunWithTimeoutExpired
```

## 🐛 Test Debug

### Verbose Output
```bash
make test-verbose
```

### Debug Mode
```bash
make test-debug
```

### Specific Test
```bash
go test -v ./internal/resolvers -run TestPresets
```

### Test with Arguments
```bash
go test -v ./internal/bench -args -test.v
```

## 📊 Coverage Analizi

### Coverage Raporu Oluştur
```bash
make test-coverage
```

### Coverage HTML Raporu
```bash
go tool cover -html=coverage.out -o coverage.html
open coverage.html
```

### Coverage Threshold
```bash
# %80 coverage kontrolü
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep total | awk '{if ($3 < 80.0) exit 1}'
```

## 🚨 Test Troubleshooting

### Test Timeout
```bash
# Timeout süresini artır
export DNS_HELPER_TIMEOUT=120s
make test
```

### Network Issues
```bash
# Network testlerini atla
make test-skip-network
```

### Slow Tests
```bash
# Yavaş testleri atla
make test-skip-slow
```

### Race Conditions
```bash
# Race detection ile test
make test-race
```

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
- name: Run Tests
  run: make ci
```

### Pre-commit Hook
```bash
make pre-commit
```

### Local CI
```bash
make ci
```

## 📝 Test Yazma Rehberi

### Test Fonksiyon Adlandırma
```go
func TestFunctionName(t *testing.T) { ... }
func TestFunctionName_Scenario(t *testing.T) { ... }
func TestFunctionName_EdgeCase(t *testing.T) { ... }
```

### Test Table Pattern
```go
func TestFunction(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected string
    }{
        {"case1", "input1", "expected1"},
        {"case2", "input2", "expected2"},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Function(tt.input)
            if result != tt.expected {
                t.Errorf("expected %s, got %s", tt.expected, result)
            }
        })
    }
}
```

### Mock Kullanımı
```go
type MockInterface interface {
    Method() string
}

type MockImplementation struct {
    returnValue string
}

func (m *MockImplementation) Method() string {
    return m.returnValue
}
```

### Test Helper Functions
```go
func assertEqual(t *testing.T, expected, actual interface{}) {
    if expected != actual {
        t.Errorf("expected %v, got %v", expected, actual)
    }
}
```

## 🎉 Test Best Practices

1. **Her fonksiyon için test yaz**
2. **Edge case'leri test et**
3. **Mock kullanarak external dependency'leri izole et**
4. **Test coverage'ı %80+ tut**
5. **Race condition'ları test et**
6. **Integration testleri ekle**
7. **Test'leri hızlı tut**
8. **Test data'yı organize et**
9. **Test helper'ları kullan**
10. **CI/CD'de otomatik test çalıştır**

## 📚 Ek Kaynaklar

- [Go Testing Package](https://golang.org/pkg/testing/)
- [Go Test Flags](https://golang.org/cmd/go/#hdr-Testing_flags)
- [Go Race Detector](https://golang.org/doc/articles/race_detector.html)
- [Go Coverage](https://blog.golang.org/cover)
