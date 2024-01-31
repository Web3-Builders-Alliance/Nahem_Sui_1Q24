/// A freely transfererrable Wrapper for custom data.
module examples::wrapper {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    /// An object with `store` can be transferred in any
    /// module without a custom transfer implementation.
    struct Wrapper<T: store> has key, store {
        id: UID,
        contents: T,
    }

    /// View function to read contents of a `Container`.
    public fun read_content<T: store>(c: &Wrapper<T>): &T {
         &c.contents
    }

    /// Anyone can create a new object
    public fun wrap<T: store>(contents: T, ctx: &mut TxContext): Wrapper<T> {
        Wrapper {
            id: object::new(ctx),
            contents,
        }
    }

    /// Unwrap and get its contents
    public fun unwrap<T: store>(w: Wrapper<T>): T {
        let Wrapper { id, contents } = w;
        object::delete(id);
        contents
    }
}

module examples::profile {
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::tx_context::TxContext;

    /// Using wrapper functionality
    use examples::wrapper::{Self, Wrapper};
        
    /// Profile information, not an object, can be wrapped
    /// into a transferable container.
    struct ProfileInfo has store {
        name: String,
        url: Url,
    }

    /// Read `name` field from `ProfileInfo`.
    public fun read_name(p: &ProfileInfo): &String {
        &p.name
    }

    /// Read `url` field from `ProfileInfo`.
    public fun read_url(p: &ProfileInfo): &Url {
        &p.url
    }

    /// Create a new `ProfileInfo` and wraps it into `Wrapper`.
    /// Then transfers it to sender
    public fun create_profile(name: vector<u8>, url: vector<u8>, ctx: &mut TxContext): Wrapper<ProfileInfo> {
        let profile = ProfileInfo {
            name: string::utf8(name),
            url: url::new_unsafe_from_bytes(url),
        };
        wrapper::wrap(profile, ctx)
    }
    
}