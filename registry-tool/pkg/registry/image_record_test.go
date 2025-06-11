package registry

import (
	"slices"
	"testing"
)

func TestImageRecord_Validate(t *testing.T) {
	tests := []struct {
		name    string
		record  ImageRecord
		wantErr bool
	}{
		{
			name: "valid record with tags",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				Tags:       []string{"1.0.0", "2.0.0"},
				TagRegex:   `^\d+\.\d+\.\d+$`,
			},
			wantErr: false,
		},
		{
			name: "valid record without tags",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				TagRegex:   `^\d+\.\d+\.\d+$`,
			},
			wantErr: false,
		},
		{
			name: "missing name",
			record: ImageRecord{
				DefaultTag: "1.0.0",
				Tags:       []string{"1.0.0"},
			},
			wantErr: true,
		},
		{
			name: "missing default tag",
			record: ImageRecord{
				Name: "test/image",
				Tags: []string{"1.0.0"},
			},
			wantErr: true,
		},
		{
			name: "invalid tag regex",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				TagRegex:   "[invalid",
			},
			wantErr: true,
		},
		{
			name: "default tag not in tags",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				Tags:       []string{"2.0.0", "3.0.0"},
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.record.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("ImageRecord.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestImageRecord_FilterTags(t *testing.T) {
	tests := []struct {
		name      string
		record    ImageRecord
		inputTags []string
		want      []string
		wantErr   bool
	}{
		{
			name: "valid regex with version comparison",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				Tags:       []string{"1.0.0", "2.0.0"},
				TagRegex:   `^\d+\.\d+\.\d+$`,
			},
			inputTags: []string{"0.9.0", "1.0.0", "1.1.0", "2.0.0", "abc", "1.0"},
			want:      []string{"2.0.0", "1.1.0", "1.0.0"},
		},
		{
			name: "empty regex",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				Tags:       []string{"1.0.0"},
			},
			inputTags: []string{"1.0.0", "2.0.0"},
			want:      []string{},
		},
		{
			name: "invalid regex",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "1.0.0",
				Tags:       []string{"1.0.0"},
				TagRegex:   "[invalid",
			},
			inputTags: []string{"1.0.0", "2.0.0"},
			wantErr:   true,
		},
		{
			name: "filter by min version",
			record: ImageRecord{
				Name:       "test/image",
				DefaultTag: "2.0.0",
				Tags:       []string{"1.0.0", "2.0.0", "3.0.0"},
				TagRegex:   `^\d+\.\d+\.\d+$`,
			},
			inputTags: []string{"1.0.0", "2.0.0", "2.1.0", "3.0.0"},
			want:      []string{"3.0.0", "2.1.0", "2.0.0"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := tt.record.FilterTags(tt.inputTags)
			if (err != nil) != tt.wantErr {
				t.Errorf("ImageRecord.FilterTags() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && !slices.Equal(got, tt.want) {
				t.Errorf("ImageRecord.FilterTags() = %v, want %v", got, tt.want)
			}
		})
	}
}
