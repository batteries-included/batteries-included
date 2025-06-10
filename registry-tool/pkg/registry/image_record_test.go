package registry

import (
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
