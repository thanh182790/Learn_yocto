#include <stdio.h>
#include <curl/curl.h>

int main(void)
{
  CURL *curl;
  CURLcode res;

  curl = curl_easy_init();
  if(curl) {
    printf("Init curl OK\n");
    printf("In file %s\n", __FILE__);
    curl_easy_cleanup(curl);
  }
  int status = system("bash -c 'echo This is executed by bash at runtime!'");

  if (status == -1) {
    perror("Failed to run bash command");
	return 1;
  }

  return 0;
}


