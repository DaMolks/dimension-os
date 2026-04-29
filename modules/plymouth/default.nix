{ config, lib, pkgs, ... }:

let
  cfg = config.dimension.plymouth;
  themeName = "dimension";
  splashImage = ../../assets/wallpapers/dimension-boot-splash-v2.png;
  themePackage = pkgs.stdenv.mkDerivation {
    pname = "dimension-plymouth-theme";
    version = "1.0.0";
    src = splashImage;
    dontUnpack = true;

    installPhase = ''
      theme_dir="$out/share/plymouth/themes/${themeName}"

      mkdir -p "$theme_dir"

      cp "$src" "$theme_dir/background.png"
      cp ${pkgs.plymouth}/share/plymouth/themes/spinner/throbber-*.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/box.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/bullet.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/entry.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/lock.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/progress_bar.png "$theme_dir/"
      cp ${pkgs.plymouth}/share/plymouth/themes/script/progress_box.png "$theme_dir/"

      cat > "$theme_dir/${themeName}.plymouth" <<EOF
[Plymouth Theme]
Name=Dimension
Description=Dimension OS boot splash
ModuleName=script

[script]
ImageDir=$theme_dir
ScriptFile=$theme_dir/${themeName}.script
EOF

      cat > "$theme_dir/${themeName}.script" <<'EOF'
Window.SetBackgroundTopColor(0.0, 0.06, 0.12);
Window.SetBackgroundBottomColor(0.0, 0.06, 0.12);

status = "normal";

background.original_image = Image("background.png");
background.image = background.original_image.Scale(Window.GetWidth(), Window.GetHeight());
background.sprite = Sprite(background.image);
background.sprite.SetPosition(Window.GetX(), Window.GetY(), 0);

spinner.sprite = Sprite();
spinner.frame = 0;
spinner.tick = 0;
spinner.frame_count = 30;
spinner.frames[0] = Image("throbber-0001.png");
spinner.frames[1] = Image("throbber-0002.png");
spinner.frames[2] = Image("throbber-0003.png");
spinner.frames[3] = Image("throbber-0004.png");
spinner.frames[4] = Image("throbber-0005.png");
spinner.frames[5] = Image("throbber-0006.png");
spinner.frames[6] = Image("throbber-0007.png");
spinner.frames[7] = Image("throbber-0008.png");
spinner.frames[8] = Image("throbber-0009.png");
spinner.frames[9] = Image("throbber-0010.png");
spinner.frames[10] = Image("throbber-0011.png");
spinner.frames[11] = Image("throbber-0012.png");
spinner.frames[12] = Image("throbber-0013.png");
spinner.frames[13] = Image("throbber-0014.png");
spinner.frames[14] = Image("throbber-0015.png");
spinner.frames[15] = Image("throbber-0016.png");
spinner.frames[16] = Image("throbber-0017.png");
spinner.frames[17] = Image("throbber-0018.png");
spinner.frames[18] = Image("throbber-0019.png");
spinner.frames[19] = Image("throbber-0020.png");
spinner.frames[20] = Image("throbber-0021.png");
spinner.frames[21] = Image("throbber-0022.png");
spinner.frames[22] = Image("throbber-0023.png");
spinner.frames[23] = Image("throbber-0024.png");
spinner.frames[24] = Image("throbber-0025.png");
spinner.frames[25] = Image("throbber-0026.png");
spinner.frames[26] = Image("throbber-0027.png");
spinner.frames[27] = Image("throbber-0028.png");
spinner.frames[28] = Image("throbber-0029.png");
spinner.frames[29] = Image("throbber-0030.png");
spinner.sprite.SetImage(spinner.frames[0]);

fun update_background()
  {
    background.image = background.original_image.Scale(Window.GetWidth(), Window.GetHeight());
    background.sprite.SetImage(background.image);
    background.sprite.SetPosition(Window.GetX(), Window.GetY(), 0);
  }

fun update_spinner_position()
  {
    spinner.x = Window.GetX() + Window.GetWidth() / 2 - spinner.frames[spinner.frame].GetWidth() / 2;
    spinner.y = Window.GetY() + Window.GetHeight() * 0.80 - spinner.frames[spinner.frame].GetHeight() / 2;
    spinner.sprite.SetPosition(spinner.x, spinner.y, 10);
  }

update_background();
update_spinner_position();

fun refresh_callback ()
  {
    update_spinner_position();

    if (status == "normal")
      {
        spinner.tick++;
        if (spinner.tick >= 2)
          {
            spinner.tick = 0;
            spinner.frame++;
            if (spinner.frame >= spinner.frame_count)
              spinner.frame = 0;
            spinner.sprite.SetImage(spinner.frames[spinner.frame]);
          }
        spinner.sprite.SetOpacity(1);
      }
    else
      {
        spinner.sprite.SetOpacity(0.4);
      }
  }

Plymouth.SetRefreshFunction (refresh_callback);

fun dialog_setup()
  {
    local.box;
    local.lock;
    local.entry;

    box.image = Image("box.png");
    lock.image = Image("lock.png");
    entry.image = Image("entry.png");

    box.sprite = Sprite(box.image);
    box.x = Window.GetX() + Window.GetWidth() / 2 - box.image.GetWidth() / 2;
    box.y = Window.GetY() + Window.GetHeight() / 2 - box.image.GetHeight() / 2;
    box.z = 10000;
    box.sprite.SetPosition(box.x, box.y, box.z);

    lock.sprite = Sprite(lock.image);
    lock.x = box.x + box.image.GetWidth() / 2 - (lock.image.GetWidth() + entry.image.GetWidth()) / 2;
    lock.y = box.y + box.image.GetHeight() / 2 - lock.image.GetHeight() / 2;
    lock.z = box.z + 1;
    lock.sprite.SetPosition(lock.x, lock.y, lock.z);

    entry.sprite = Sprite(entry.image);
    entry.x = lock.x + lock.image.GetWidth();
    entry.y = box.y + box.image.GetHeight() / 2 - entry.image.GetHeight() / 2;
    entry.z = box.z + 1;
    entry.sprite.SetPosition(entry.x, entry.y, entry.z);

    global.dialog.box = box;
    global.dialog.lock = lock;
    global.dialog.entry = entry;
    global.dialog.bullet_image = Image("bullet.png");
    dialog_opacity(1);
  }

fun dialog_opacity(opacity)
  {
    dialog.box.sprite.SetOpacity(opacity);
    dialog.lock.sprite.SetOpacity(opacity);
    dialog.entry.sprite.SetOpacity(opacity);
    for (index = 0; dialog.bullet[index]; index++)
      {
        dialog.bullet[index].sprite.SetOpacity(opacity);
      }
  }

fun display_normal_callback ()
  {
    global.status = "normal";
    if (global.dialog)
      dialog_opacity(0);
  }

fun display_password_callback (prompt, bullets)
  {
    global.status = "password";

    if (!global.dialog)
      dialog_setup();
    else
      dialog_opacity(1);

    for (index = 0; dialog.bullet[index] || index < bullets; index++)
      {
        if (!dialog.bullet[index])
          {
            dialog.bullet[index].sprite = Sprite(dialog.bullet_image);
            dialog.bullet[index].x = dialog.entry.x + index * dialog.bullet_image.GetWidth();
            dialog.bullet[index].y = dialog.entry.y + dialog.entry.image.GetHeight() / 2 - dialog.bullet_image.GetHeight() / 2;
            dialog.bullet[index].z = dialog.entry.z + 1;
            dialog.bullet[index].sprite.SetPosition(dialog.bullet[index].x, dialog.bullet[index].y, dialog.bullet[index].z);
          }

        if (index < bullets)
          dialog.bullet[index].sprite.SetOpacity(1);
        else
          dialog.bullet[index].sprite.SetOpacity(0);
      }
  }

Plymouth.SetDisplayNormalFunction(display_normal_callback);
Plymouth.SetDisplayPasswordFunction(display_password_callback);

progress_box.image = Image("progress_box.png");
progress_box.sprite = Sprite(progress_box.image);
progress_box.x = Window.GetX() + Window.GetWidth() / 2 - progress_box.image.GetWidth() / 2;
progress_box.y = Window.GetY() + Window.GetHeight() * 0.92 - progress_box.image.GetHeight() / 2;
progress_box.sprite.SetPosition(progress_box.x, progress_box.y, 2);

progress_bar.original_image = Image("progress_bar.png");
progress_bar.sprite = Sprite();
progress_bar.x = progress_box.x + (progress_box.image.GetWidth() - progress_bar.original_image.GetWidth()) / 2;
progress_bar.y = progress_box.y + (progress_box.image.GetHeight() - progress_bar.original_image.GetHeight()) / 2;
progress_bar.sprite.SetPosition(progress_bar.x, progress_bar.y, 3);

fun progress_callback (duration, progress)
  {
    width = Math.Int(progress_bar.original_image.GetWidth() * progress);
    if (width < 1)
      width = 1;

    progress_bar.image = progress_bar.original_image.Scale(width, progress_bar.original_image.GetHeight());
    progress_bar.sprite.SetImage(progress_bar.image);
  }

Plymouth.SetBootProgressFunction(progress_callback);

message.sprite = Sprite();
message.sprite.SetPosition(0, 0, 10001);

fun display_message_callback (text)
  {
    message.image = Image.Text(text, 0.91, 0.94, 0.97);
    message.sprite.SetImage(message.image);
    message.sprite.SetPosition(
      Window.GetX() + Window.GetWidth() / 2 - message.image.GetWidth() / 2,
      Window.GetY() + Window.GetHeight() * 0.87,
      10001
    );
  }

fun hide_message_callback (text)
  {
    message.sprite.SetImage(Image.Text("", 0.91, 0.94, 0.97));
  }

Plymouth.SetDisplayMessageFunction(display_message_callback);
Plymouth.SetHideMessageFunction(hide_message_callback);
EOF
    '';
  };
in
{
  options.dimension.plymouth.enable = lib.mkEnableOption "Dimension Plymouth boot splash";

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      theme = themeName;
      themePackages = [ themePackage ];
    };

    boot.kernelParams = lib.mkAfter [ "quiet" "splash" ];
  };
}
