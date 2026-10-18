/* string.h */

#ifndef _MYSTRING_H
#define _MYSTRING_H 1

#ifndef size_t
#define size_t unsigned long
#endif
int my_strcasecmp(const char *s, const char *d);
int my_strncasecmp(const char *s, const char *d, size_t l);

#endif

