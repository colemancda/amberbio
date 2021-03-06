#include "geo_parser.h"

double parse_double(const char* str, const long str_len)
{
        char* endptr = NULL;
        double value = strtod(str, &endptr);
        return endptr == str + str_len ? value : nanf(NULL);
}


struct gds {
        bool valid;
        char* header;
        long number_of_molecules;
        long number_of_headers;
        char** headers;
        long sample_column_min;
        long number_of_samples;
        char** sample_names;
        long number_of_molecule_annotations;
        char** molecule_annotation_names;
        char*** molecule_annotation_values;


        double* values;
};

bool gds_valid(struct gds* gds)
{
        return gds->valid;
}

char* gds_header(struct gds* gds)
{
        return gds->header;
}

long gds_number_of_samples(struct gds* gds)
{
        return gds->number_of_samples;
}

char** gds_samples_names(struct gds* gds)
{
        return gds->sample_names;
}

long gds_number_of_molecules(struct gds* gds)
{
        return gds->number_of_molecules;
}

long gds_number_of_molecule_annotations(struct gds* gds)
{
        return gds->number_of_molecule_annotations;
}

char** gds_molecule_annotations(struct gds* gds)
{
        return gds->molecule_annotation_names;
}





double* gds_values(struct gds* gds)
{
        return gds->values;
}



struct gds* gds_new(const void* bytes, const long length)
{
        struct gds* gds = malloc(sizeof(*gds));
        gds->valid = false;

        const char* string = (const char*) bytes;
        const char* end = string + length;
        if (*(end - 1) != '\n') return gds;

        const char* position_of_dataset_title = strnstr(string, "!dataset_title", length);
        if (position_of_dataset_title == NULL) return gds;

        const char* position_of_caret_after_dataset_title = strnstr(position_of_dataset_title, "^", end - position_of_dataset_title);
        if (position_of_caret_after_dataset_title == NULL) return gds;

        long header_length = position_of_caret_after_dataset_title - position_of_dataset_title;
        gds->header = malloc(header_length + 1);
        memcpy(gds->header, position_of_dataset_title, header_length);
        gds->header[header_length] = '\0';

        const char* position_of_feature_count = strnstr(position_of_dataset_title, "!dataset_feature_count", end - position_of_dataset_title);
        gds->number_of_molecules = strtol(position_of_feature_count + 25, NULL, 10);

        const char* position_dataset_table_begin = strnstr(position_of_caret_after_dataset_title, "!dataset_table_begin", end - position_of_caret_after_dataset_title);
        if (position_dataset_table_begin == NULL) return gds;
        const char* position_headers = position_dataset_table_begin + 21;
        if (position_headers - string > length - 1) return gds;
        gds->number_of_headers = 1;
        for (const char* c = position_headers; *c != '\n'; c++) {
                if (*c == '\t') gds->number_of_headers++;
        }
        gds->headers = malloc(gds->number_of_headers * sizeof(*gds->headers));
        const char* position_header_start = position_headers;
        for (long i = 0; i < gds->number_of_headers; i++) {
                const char* position;
                for (position = position_header_start; *position != '\t' && *position != '\n'; position++);
                long header_length = position - position_header_start;
                char* header = malloc(header_length + 1);
                memcpy(header, position_header_start, header_length);
                header[header_length] = '\0';
                gds->headers[i] = header;
                position_header_start = position + 1;
        }

        gds->sample_column_min = -1;
        gds->number_of_samples = 0;
        for (long i = 0; i < gds->number_of_headers; i++) {
                if (strstr(gds->headers[i], "GSM") == gds->headers[i]) {
                        if (gds->sample_column_min == -1) {
                                gds->sample_column_min = i;
                        }
                        gds->number_of_samples++;
                } else if (gds->sample_column_min != -1) {
                        break;
                }
        }

        gds->sample_names = malloc(gds->number_of_samples * sizeof(*gds->sample_names));
        for (long i = 0; i < gds->number_of_samples; i++) {
                gds->sample_names[i] = gds->headers[gds->sample_column_min + i];
        }

        const char* position_cells = strnstr(position_headers, "\n", end - position_headers - 1) + 1;

        const char* position_dataset_table_end = strnstr(position_cells, "!dataset_table_end", end - position_cells);
        if (position_dataset_table_end == NULL) return gds;

        if (gds->number_of_molecules == 0 || gds->number_of_samples == 0) return gds;

        gds->values = malloc(gds->number_of_samples * gds->number_of_molecules * sizeof(double));

        bool is_annotation[gds->number_of_headers];
        gds->number_of_molecule_annotations = 0;
        for (long i = 0; i < gds->number_of_headers; i++) {
                if (i < gds->sample_column_min) {
                        is_annotation[i] = true;
                        gds->number_of_molecule_annotations++;
                } else if (i < gds-> sample_column_min + gds->number_of_samples) {
                        is_annotation[i] = false;
                } else if (gds->number_of_molecule_annotations < 8) {
                        is_annotation[i] = true;
                        gds->number_of_molecule_annotations++;
                } else {
                        is_annotation[i] = false;
                }
        }

        gds->molecule_annotation_names = malloc(gds->number_of_molecule_annotations * sizeof(*gds->molecule_annotation_names));
        long counter = 0;
        for (long i = 0; i < gds->number_of_headers; i++) {
                if (is_annotation[i]) {
                        gds->molecule_annotation_names[counter] = gds->headers[i];
                        counter++;
                }
        }




        const char* position_start = position_cells;
        const char* position = position_start;
        long row = 0;
        long col = 0;
        while (position < position_dataset_table_end) {
                if (row >= gds->number_of_molecules || col >= gds->number_of_headers) return gds;
                if (*position == '\t' || *position == '\n') {
                        long cell_length = position - position_start;
                        if (col >= gds->sample_column_min  && col < gds->sample_column_min + gds->number_of_samples) {
                                char str[cell_length + 1];
                                memcpy(str, position_start, cell_length);
                                str[cell_length] = '\0';
                                char* endptr = str;

                                double value = strtod(str, &endptr);
                                if (endptr != str + cell_length) {
                                        value = nanf(NULL);
                                }

                                long index = row * gds->number_of_samples + col - gds->sample_column_min;
                                gds->values[index] = value;

                                if (row <= 1) {
                                        printf("%li, %li, %li, %f\n", row, col, cell_length, value);
                                }

                        }



                        if (*position == '\t') {
                                col++;
                        } else {
                                row++;
                                col = 0;
                        }

                        position++;
                        position_start = position;


                } else {
                        position++;
                }
        }














//
//        long position_of_dataset_table_begin = -1;
//
//        for (long i = 0; i < length - 19; i++) {
//                if (strncmp(string + i, "!dataset_table_begin", 20) == 0) {
//                        position_of_dataset_table_begin = i;
//                        break;
//                }
//        }





//        if (position_of_dataset_table_begin == 1) return;

//        long header_length = position_of_dataset_table_begin - 1;




//        long result_length = cstring_max_length > header_length ? header_length : cstring_max_length;
//        memcpy(cstring, bytes, result_length);
//        cstring[result_length + 1] = '\0';

        gds->valid = true;

        return gds;
}
