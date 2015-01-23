#ifndef _CHANNEL_LOCATIONS_H
#define _CHANNEL_LOCATIONS_H

/* structure for the channel locations compound data type */
struct channel_locations {
    char  *labels;
    char  *type;
    double theta;
    double radius;
    double X;
    double Y;
    double Z;
    double sph_theta;
    double sph_phi;
    double sph_radius;
    double urchan;
    char  *ref;
};

/*
 * prints the fields of a struct channel_locations
 * \param chan the struct channel_locations to print
 */
void print_channel_locations(struct channel_locations chan) {
    printf("%-5s%-5s%12f%12f%12f%12f%12f%12f%12f%12f%12f%12s\n",
           chan.labels, chan.type, chan.theta, chan.radius, chan.X, chan.Y,
           chan.Z, chan.sph_theta, chan.sph_phi, chan.sph_radius, chan.urchan,
           chan.ref);
}

#endif
