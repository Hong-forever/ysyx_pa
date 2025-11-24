#include "common.h"
#include <getopt.h>

static char *img_file = NULL;

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"batch"        , no_argument       , NULL, 'b'},
        {"log"          , required_argument , NULL, 'l'},
        {"diff"         , required_argument , NULL, 'd'},
        {"port"         , required_argument , NULL, 'p'},
        {"help"         , no_argument       , NULL, 'h'},
        {0              , 0                 , NULL,  0 },
    };

    int o;
    while( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
        switch(o) {
            case 'b': /*sdb_set_batch_mode();*/ break;
            case 'p': /*scanf(optarg, "%d", &difftest_port);*/ break;
            case 'l': /*log_file = optarg;*/ break;
            case 'd': /*diff_so_file = optarg;*/ break;
            case  1 : img_file = optarg; return 0;
            default :
                printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
                printf("\t-b,--batch              run with batch mode\n");
                printf("\t-l,--log=FILE           output log to FILE\n");
                printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
                printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
                printf("\n");
                exit(0);
        }
    }

    return 0;
}

static size_t load_img()
{
    if (img_file == NULL) {
        printf("No image give\n");
        return 0;
    }

    FILE *fp = fopen(img_file, "rb");
    assert(fp);

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    printf("The image is %s, size = 0x%08lx\n", img_file, size);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(guest_to_host(0), size, 1, fp);
    assert(ret == 1);

    fclose(fp);
    return size;
}

void init_monitor(int argc, char *argv[]) {

    parse_args(argc, argv);

    size_t size = load_img();

    // IFDEF(CONFIG_FTRACE, init_ftrace(elf_file));

    // IFDEF(CONFIG_DEVICE, init_device());

    // init_difftest(diff_so_file, img_size, difftest_port);

    // init_sdb();

    // IFDEF(CONFIG_ITRACE, init_disasm());

    printf("Welcome to NPC!\n");
}