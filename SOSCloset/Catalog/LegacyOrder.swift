// The pieces imported from the prototype's catalog, newest first (the site's app/settings/legacy-order.ts, in
// data/catalog.json order). Shopify gives them all the same created date (one import), so this list orders them;
// anything listed later is newer and sorts by its own created date ahead of these. Matched by the id:<id> tag.
nonisolated enum LegacyOrder {
    static let ids: [String] = [
        "coach-legacy", "yz-desert-sage", "yz-carbon", "yz-linen", "yz-dazzling-blue", "c178", "c179", "herm-orange",
        "choo", "coach-watch", "yuroz-jacket", "bamboo", "c115", "c49", "c181", "c2", "c114", "yurman", "c45",
        "c121", "brunello", "akris-dress", "akris-sweater", "lafayette", "coppley", "c118", "c120", "c69", "c14",
        "c52", "c112", "c70", "c141", "c50", "c12", "c15", "c43", "c54", "c13", "c85", "c149", "c147", "staud-gus",
        "gucci-sun", "c116", "c68", "c75", "c109", "c62", "c150", "c151", "c53", "sc035", "sc034", "sc033", "sc030",
        "sc029", "sc028", "sc027", "sc026", "paige-boots", "c77", "sc024", "sc023", "sc021", "sc020", "sc019",
        "sc017", "sc016", "sc014", "sc013", "sc012", "gwyn", "sc009", "sc007", "sc005", "lex", "sc004", "sc003",
        "sc002", "vestirsi", "gucci-blazer", "pooh-vest", "sung-skirt", "celine", "camerino", "valentino", "c1",
        "c142", "c48", "c51", "c19", "c125", "c46", "c145", "c184", "c183", "c40", "c39", "c24", "theory-pants",
        "cdc-mamika", "sandro-trousers", "cdc-denim", "c25", "c105", "c97", "c104", "c163", "c164", "gruppo",
        "miumiu", "c182", "c102", "c153", "ulla-top", "kenzo-derby", "c26", "c156", "c158", "jackie", "herm-navy",
        "av21-silver", "av21-paisley", "bordeaux-blazer", "leiber", "c168", "c55", "c89", "c65", "c83", "c91", "c86",
        "herm-blue", "yeezy", "vbc", "av21-dinner", "c8", "av21-navy", "c88", "c23", "depinna", "talbot", "cmv",
        "c111", "c94", "c28", "c93", "c9", "c37", "c36", "c171", "c172", "c42", "c27", "c90", "c6", "pm-cashmere",
        "paul-stuart-zip", "monkeys", "pinal", "archie", "c154", "c169", "c72", "c167", "c58", "c76", "c146", "c144",
        "zegna", "c64", "bally", "c98", "c59", "c63", "c176", "c103", "c177", "c162", "c35", "c30", "c110", "c124",
        "c18", "c166", "c56", "c152", "resin", "arabia", "c16", "c17", "balenciaga-crossbody", "c29", "c41", "c22",
        "c87", "nike-76ers",
    ]

    /// Where each id sorts (the last place wins if an id were listed twice, as with the site's Map).
    static let index: [String: Int] = Dictionary(ids.enumerated().map { ($1, $0) }, uniquingKeysWith: { _, last in last })
}
